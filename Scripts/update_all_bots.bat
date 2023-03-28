@echo off
for /D %%f in (%userprofile%\Firemodels*) do (
  cd %%f\bot
  echo -----------------------------------
  echo %%f
  echo -----------------------------------
  git remote update
  git merge origin/master
)
