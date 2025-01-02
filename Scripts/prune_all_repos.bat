@echo off
for /D %%f in (%userprofile%\Firemodels*) do (
  cd %%f\bot\scripts
  echo -----------------------------------
  echo %%f
  echo -----------------------------------
  call prune_repos
)
