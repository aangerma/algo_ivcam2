:: run script from hosting directory
:: ..\..\..\algo_automation\tools\turn_in.py --repo-path ..\..\..\algo_ivcam2 --on-to-branch master --jenkins-job algo_ivcam2_Gated__Flow

..\..\..\algo_automation\tools\turn_in.py --repo-path ..\..\..\algo_ivcam2 --on-to-branch master

if %errorlevel%==0 (
    ..\..\..\algo_automation\tools\gitMerge.py --repo-path ..\..\..\algo_ivcam2 --on-to-branch master
    )