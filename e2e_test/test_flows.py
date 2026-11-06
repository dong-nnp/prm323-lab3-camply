"""Every parameterized invocation is one independent ARTEMIS instruction."""


def test_evia_flow(session, case_id, repeat):
    session.execute(case_id, repeat)
