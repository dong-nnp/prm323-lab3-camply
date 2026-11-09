import { getRemoteConfig, RemoteConfigTemplate } from 'firebase-admin/remote-config';
import { Firestore } from 'firebase-admin/firestore';
import { GoogleAuth } from 'google-auth-library';
import { z } from 'zod';
import { requireAdmin } from './admin_catalog.js';
import { Actor, coins, empty, fail } from './shared.js';
import { dailyRewardPolicy, dailyRewardsSchema, defaultDailyRewards } from './policy.js';

const daysInput = z.object({ days: z.union([z.literal(7), z.literal(30)]) }).strict();
const analyticsSource = z.enum(['configured', 'android', 'web']).default('configured');
const analyticsInput = z.union([
  daysInput.extend({ source: analyticsSource }),
  z.object({ realtime: z.literal(true), source: analyticsSource }).strict(),
]);

export function analyticsReportQuery(raw: unknown, stream?: string) {
  const input = analyticsInput.parse(raw);
  const { source } = input;
  const dimensionFilter = source === 'configured'
    ? (stream ? { filter: { fieldName: 'streamId', stringFilter: { matchType: 'EXACT', value: stream } } } : undefined)
    : { filter: { fieldName: 'platform', stringFilter: { matchType: 'EXACT', value: source === 'android' ? 'Android' : 'web', caseSensitive: false } } };
  return {
    ...('days' in input
      ? { dateRanges: [{ startDate: String(input.days - 1) + 'daysAgo', endDate: 'today' }] }
      : { minuteRanges: [{ startMinutesAgo: 29, endMinutesAgo: 0 }] }),
    dimensions: [{ name: 'eventName' }],
    metrics: [{ name: 'eventCount' }, { name: 'realtime' in input ? 'activeUsers' : 'totalUsers' }],
    orderBys: [{ metric: { metricName: 'eventCount' }, desc: true }],
    limit: '25',
    ...(dimensionFilter && { dimensionFilter }),
  };
}
const dailyRewardInput = z.object({
  etag: z.string().min(1).max(500),
  day: z.number().int().min(1).max(7),
  coins,
}).strict();
const milestoneInput = dailyRewardInput.pick({ etag: true }).extend({
  milestones: z.object({
    enabled: z.boolean(),
    intro: z.string().trim().min(1).max(500),
  }).strict(),
});
const configInput = z.union([dailyRewardInput, milestoneInput]);
const rewardKey = 'daily_checkin_rewards';
const milestoneEnabledKey = 'event_milestones_enabled';
const milestoneIntroKey = 'event_milestones_intro';
const defaultMilestoneIntro = 'Complete event milestones to earn extra Evia Coin.';

function parameterMap(template: RemoteConfigTemplate, key: string) {
  const group = Object.values(template.parameterGroups ?? {}).find(item => key in item.parameters);
  return group?.parameters ?? template.parameters;
}

function parameterDefault(template: RemoteConfigTemplate, key: string) {
  const value = parameterMap(template, key)[key]?.defaultValue;
  return value && 'value' in value ? value.value : undefined;
}

function publishedRewards(template: RemoteConfigTemplate): readonly number[] {
  const value = parameterDefault(template, rewardKey);
  if (value === undefined) return defaultDailyRewards;
  try {
    return dailyRewardsSchema.parse(JSON.parse(value));
  } catch {
    fail('REMOTE_CONFIG_REWARD_INVALID');
  }
}

function publishedMilestones(template: RemoteConfigTemplate) {
  const enabled = parameterDefault(template, milestoneEnabledKey)?.trim().toLowerCase();
  const intro = parameterDefault(template, milestoneIntroKey)?.trim();
  return {
    enabled: enabled !== 'false',
    intro: intro && intro.length <= 500 ? intro : defaultMilestoneIntro,
  };
}

function remoteConfigView(template: RemoteConfigTemplate, appliedRewards: readonly number[]) {
  return {
    etag: template.etag,
    version: template.version?.versionNumber ?? null,
    rewards: publishedRewards(template),
    appliedRewards,
    milestones: publishedMilestones(template),
  };
}

export function updateDailyReward(template: RemoteConfigTemplate, input: z.infer<typeof dailyRewardInput>) {
  if (template.etag !== input.etag) fail('REMOTE_CONFIG_CHANGED', 'aborted');
  const rewards = [...publishedRewards(template)];
  rewards[input.day - 1] = input.coins;
  const parameters = parameterMap(template, rewardKey);
  parameters[rewardKey] = {
    ...parameters[rewardKey],
    defaultValue: { value: JSON.stringify(rewards) },
    valueType: 'JSON',
  };
  return template;
}

export function updateMilestonePresentation(template: RemoteConfigTemplate, raw: unknown) {
  const { etag, milestones } = milestoneInput.parse(raw);
  if (template.etag !== etag) fail('REMOTE_CONFIG_CHANGED', 'aborted');
  const enabled = parameterMap(template, milestoneEnabledKey);
  enabled[milestoneEnabledKey] = {
    ...enabled[milestoneEnabledKey],
    defaultValue: { value: String(milestones.enabled) },
    valueType: enabled[milestoneEnabledKey]?.valueType ?? 'BOOLEAN',
  };
  const intro = parameterMap(template, milestoneIntroKey);
  intro[milestoneIntroKey] = {
    ...intro[milestoneIntroKey],
    defaultValue: { value: milestones.intro },
    valueType: 'STRING',
  };
  return template;
}

const analyticsAuth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/analytics.readonly'] });
const bigQueryAuth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/bigquery'] });

function cloudOnly() {
  if (process.env.FUNCTIONS_EMULATOR === 'true') fail('CLOUD_INTEGRATION_UNAVAILABLE_IN_EMULATOR');
}

function upstream(error: unknown, service: string): never {
  const detail = error as { code?: string; response?: { status?: number } };
  const status = detail?.response?.status;
  if (status === 409 || status === 412 || detail?.code === 'remote-config/aborted') fail('REMOTE_CONFIG_CHANGED', 'aborted');
  if (status === 401 || status === 403 || detail?.code === 'remote-config/unauthenticated' ||
      detail?.code === 'remote-config/permission-denied') fail(service + '_ACCESS_DENIED');
  fail(service + '_UNAVAILABLE', 'unavailable');
}

type AnalyticsReport = {
  rows?: { dimensionValues: { value: string }[]; metricValues: { value: string }[] }[];
};
type BigQueryResult = {
  jobComplete: boolean;
  jobReference?: { jobId: string; projectId: string; location?: string };
  rows?: { f: { v: string | null }[] }[];
};

export function adminIntegrations(db: Firestore) {
  const policy = dailyRewardPolicy(db);
  return {
    getAdminRemoteConfig: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      empty.parse(raw);
      cloudOnly();
      const [template, applied] = await Promise.all([
        getRemoteConfig().getTemplate().catch(error => upstream(error, 'REMOTE_CONFIG')),
        policy.get(),
      ]);
      return remoteConfigView(template, applied.get('rewards') ?? defaultDailyRewards);
    },
    publishAdminRemoteConfig: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const input = configInput.parse(raw);
      cloudOnly();
      const service = getRemoteConfig();
      let template = await service.getTemplate().catch(error => upstream(error, 'REMOTE_CONFIG'));
      if (template.etag !== input.etag) fail('REMOTE_CONFIG_CHANGED', 'aborted');
      const rewardsBefore = publishedRewards(template);
      const changed = 'milestones' in input
        ? parameterDefault(template, milestoneEnabledKey) !== String(input.milestones.enabled) ||
          parameterDefault(template, milestoneIntroKey) !== input.milestones.intro
        : rewardsBefore[input.day - 1] !== input.coins;
      if (changed) {
        const updated = 'milestones' in input
          ? updateMilestonePresentation(template, input)
          : updateDailyReward(template, input);
        try {
          const validated = await service.validateTemplate(updated);
          template = await service.publishTemplate(validated);
        } catch (error) {
          upstream(error, 'REMOTE_CONFIG');
        }
      }
      if ('milestones' in input) {
        const applied = await policy.get();
        return remoteConfigView(template, applied.get('rewards') ?? defaultDailyRewards);
      }
      // Daily check-in reads this policy in the same transaction as the wallet.
      // Reapplying a published value repairs a failed write without publishing again.
      const version = Number(template.version?.versionNumber);
      const rewards = publishedRewards(template);
      await db.runTransaction(async tx => {
        const current = await tx.get(policy);
        if (!Number.isSafeInteger(version) || version < 1) {
          if (!current.exists && rewards === defaultDailyRewards) return;
          fail('REMOTE_CONFIG_UNAVAILABLE', 'unavailable');
        }
        if ((current.get('version') ?? 0) > version) fail('REMOTE_CONFIG_CHANGED', 'aborted');
        if (current.get('version') !== version) tx.set(policy, { rewards, version });
      });
      return remoteConfigView(template, rewards);
    },
    getAdminAnalyticsReport: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const input = analyticsInput.parse(raw);
      const { source } = input;
      const method = 'realtime' in input ? 'runRealtimeReport' : 'runReport';
      cloudOnly();
      const property = process.env.ADMIN_GA4_PROPERTY_ID;
      const stream = process.env.ADMIN_GA4_STREAM_ID;
      if (!property || !/^\d+$/.test(property) || (stream && !/^\d+$/.test(stream))) fail('ANALYTICS_NOT_CONFIGURED');
      try {
        const { data } = await analyticsAuth.request<AnalyticsReport>({
          url: 'https://analyticsdata.googleapis.com/v1beta/properties/' + property + ':' + method,
          method: 'POST',
          timeout: 12000,
          data: analyticsReportQuery(raw, stream),
        });
        return { ...('days' in input ? { days: input.days } : { realtime: true }), scope: source === 'configured' ? (stream ? 'stream' : 'property') : source, items: (data.rows ?? []).map(row => ({
          name: row.dimensionValues[0].value, count: row.metricValues[0].value, users: row.metricValues[1].value,
        })) };
      } catch (error) {
        upstream(error, 'ANALYTICS');
      }
    },
    getAdminCrashlyticsReport: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const { days } = daysInput.parse(raw);
      cloudOnly();
      const table = process.env.ADMIN_CRASHLYTICS_TABLE;
      if (!table || !/^[a-z][a-z0-9-]+\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+$/.test(table)) fail('CRASHLYTICS_NOT_CONFIGURED');
      const project = table.split('.')[0];
      const url = 'https://bigquery.googleapis.com/bigquery/v2/projects/' + project;
      let result: BigQueryResult;
      try {
        ({ data: result } = await bigQueryAuth.request<BigQueryResult>({
          url: url + '/queries',
          method: 'POST',
          timeout: 12000,
          data: {
            query: [
              'SELECT issue_id, error_type, COUNT(DISTINCT event_id),',
              "FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', MAX(event_timestamp), 'UTC'),",
              'ARRAY_AGG(application.display_version IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)]',
              'FROM `' + table + '`',
              'WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL @days DAY)',
              'AND issue_id IS NOT NULL GROUP BY issue_id, error_type ORDER BY MAX(event_timestamp) DESC LIMIT 25',
            ].join(' '),
            useLegacySql: false,
            maximumBytesBilled: '1073741824',
            parameterMode: 'NAMED',
            queryParameters: [{ name: 'days', parameterType: { type: 'INT64' }, parameterValue: { value: String(days) } }],
            timeoutMs: 6000,
          },
        }));
        for (let attempt = 0; !result.jobComplete && result.jobReference && attempt < 2; attempt++) {
          const job = result.jobReference;
          ({ data: result } = await bigQueryAuth.request<BigQueryResult>({
            url: url + '/queries/' + encodeURIComponent(job.jobId),
            params: { timeoutMs: 3000, location: job.location },
            timeout: 6000,
          }));
        }
      } catch (error) {
        upstream(error, 'CRASHLYTICS');
      }
      if (!result.jobComplete) fail('CRASHLYTICS_QUERY_PENDING', 'unavailable');
      return { days, items: (result.rows ?? []).map(({ f }) => ({
        issueId: f[0].v, type: f[1].v, count: f[2].v, lastSeen: f[3].v, version: f[4].v,
      })) };
    },
  };
}
