:: run tests tests
@echo off
::echo %1
if "%1"=="" (
    echo "missing input: list for test list OR test name to execute test"
    GOTO:EOF
    )
if %1==list (
    echo "get test list"
    slash list --only-tests --show-tags -f Avv/tests/test_list.txt
) else (
    echo "run tests"
    slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k %1
)
::slash list --only-tests --show-tags -f Avv/tests/test_list.txt;
::slash run -vv -l Avv/logs/ -o log.highlights_subpath={context.session.id}/highlights.log -f Avv/tests/test_list.txt -k %1

