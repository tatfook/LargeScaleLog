cd /d D:\git\LargeScaleLogSystem\UnitTest
echo start UnitTest
start "UnitTest" /D "D:\git\LargeScaleLogSystem" npl -d bootstrapper="UnitTest.lua" servermode="true" dev="../../" raftMode="server" baseDir="" mpPort="8088"

pause

   