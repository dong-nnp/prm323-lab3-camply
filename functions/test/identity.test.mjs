import assert from 'node:assert/strict';
import test from 'node:test';
import { emailAddress, fptStudentId } from '../lib/identity.js';

test('email syntax is provider-neutral and normalized', () => {
 for(const value of [' person@gmail.com ','Person@Outlook.COM','name+event@yahoo.co.uk','student@custom-domain.org','student@fpt.edu.vn','student@fe.edu.vn','student@fpt.edu.vn.attacker.test']) assert(emailAddress.safeParse(value).success,value);
 assert.equal(emailAddress.parse(' Person@Gmail.COM '),'person@gmail.com');
 for(const value of ['', 'no-at-sign','a@@example.com','person@example','person@.com','person@-example.com','.person@example.com','a..b@example.com','a b@example.com','a@example..com',`${'a'.repeat(245)}@example.com`]) assert.equal(emailAddress.safeParse(value).success,false,value);
 assert.equal(fptStudentId.parse(' se123456 '),'SE123456');
 assert.equal(fptStudentId.safeParse('STU-123456').success,false);
});
