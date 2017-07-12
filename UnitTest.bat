cd /d C:\Users\linfe\LargeScaleLogSystem\UnitTest
echo start UnitTest
start "UnitTest" /D "C:\Users\linfe\LargeScaleLogSystem" npl -d bootstrapper="UnitTest.lua" servermode="true" dev="../../" raftMode="server" baseDir="" mpPort="8088"

pause

   