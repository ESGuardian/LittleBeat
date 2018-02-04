@ECHO OFF

echo Check operating system ...
if defined PROGRAMFILES(X86) (
    msiexec /i littlebeat_agent_64.msi
) else (
    mswexec /i littlebeat_agent_32.msi
)
