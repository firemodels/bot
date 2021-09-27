from sys import platform
import sys
from functools import partial

if platform != "win32":
  print("***error: this script only runs on Windows computers")
  sys.exit()

from tkinter import *
import os

root = Tk()

# directory locations

repo_root = "..\\..\\"
bot_repo = repo_root + "bot\\"
smv_repo = repo_root + "smv\\"
webscript_dir  = bot_repo + "Bundle\\webscripts\\"

def restart_program():
    python = sys.executable
    os.execl(python, python, * sys.argv)

# link windows batch files to python commands

def show_branch():                 os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():                  os.system("start " + webscript_dir + "webSHOW_revisions")
def update_windows():              os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_all():                  os.system("start " + webscript_dir + "webUPDATErepos")
def set_revision():                os.system("start " + webscript_dir + "webSET_bundle_revision")
def build_smv_win_inc():           os.system("start " + webscript_dir + "webBUILDsmv windows testinc")
def build_smv(platform, option):   os.system("start " + webscript_dir + "webBUILDsmv "      + platform + " " + option )
def build_lib(platform):           os.system("start " + webscript_dir + "webBUILDlibs "     + platform)
def build_util(platform):          os.system("start " + webscript_dir + "webBUILDallprog "  + platform)
def bundle_smv(platform, option):  os.system("start " + webscript_dir + "webPACKAGEsmv "    + platform + " " + option )
def install_smv(platform, option): os.system("start " + webscript_dir + "webINSTALLsmv "    + platform + " " + option )
def archive_smv(platform, option): os.system("start " + webscript_dir + "webARCHIVEbundle " + platform + " " + option )
def upload_bundle():               os.system("start " + webscript_dir + "webUPLOADsmv2git")
def copy_bundle():                 os.system("start " + webscript_dir + "webCOPYsmv")
def webCOPYhome2config():          os.system("start " + webscript_dir + "webCOPYhome2config")
def webCOPYconfig2home():          os.system("start " + webscript_dir + "webCOPYconfig2home")
def webSYNCHfds2smv():             os.system("start " + webscript_dir + "webSYNCHfds2smv")
def webSYNCHsmv2fds():             os.system("start " + webscript_dir + "webSYNCHsmv2fds")
def clean_repos_win():             os.system("start " + webscript_dir + "webclean_win")
def clean_repos_all():             os.system("start " + webscript_dir + "webclean_all")
def clean_uploads_win():           os.system("start " + webscript_dir + "webCleanUploadWin")
def clean_uploads_all():           os.system("start " + webscript_dir + "webCleanUploadAll")
def clean_smv_win():               os.system("start " + webscript_dir + "webCleanWinSMVobjs")
def clean_smv_all():               os.system("start " + webscript_dir + "webCleanSMVobjs")
def set_branch():                  os.system("start " + webscript_dir + "webSET_branches")
def add_notes():                   os.system("start " + webscript_dir + "webGET_smvlog")
def edit_notes():                  os.system("start " + webscript_dir + "webEDIT_release_notes")
def view_notes():                  os.system("start " + webscript_dir + "webVIEW_release_notes")
def edit_this_page():              os.system("start " + webscript_dir + "webEDIT_build_smokeview_py")
def edit_settings():               os.system("start " + webscript_dir + "webEDIT_setup")

root.title('Smokeview')
root.resizable(0, 0)

# ------------------------- Show repo revisions ------------------------------

R=0
Label(root, text="Repos").grid(column=1, row=R, columnspan=2)

R=R+1
Label(root, text="Show:").grid(column=0, row=R, sticky=E)
Button(root, text="Branch",       command=show_branch).grid(row=R, column=1)
Button(root, text="Revision",     command=show_repos).grid(row=R, column=2)

# ------------------------- Update repos ------------------------------

R=R+1
Label(root, text="Update:").grid(column=0, row=R, sticky=E)
Button(root, text="Windows",    command=update_windows).grid(row=R, column=1)
Button(root, text="All",        command=update_all).grid(row=R, column=2)

# ------------------------- Set  ------------------------------

R=R+1
Label(root, text="Set:").grid(column=0, row=R, sticky=E)
Button(root, text="Bundle rev",      command=set_revision).grid(row=R, column=1)
Button(root, text="Master branch",   command=set_branch).grid(row=R, column=2)

# ------------------------- clean ------------------------------

R=R+1
Label(root, text="Clean").grid(column=1, row=R, columnspan=2)

R=R+1
Label(root, text="repos:").grid(column=0, row=R, sticky=E)
Button(root, text="Windows",  command=clean_repos_win).grid(row=R, column=1)
Button(root, text="All",      command=clean_repos_all).grid(row=R, column=2)

R=R+1
Label(root, text="uploads:").grid(column=0, row=R, sticky=E)
Button(root, text="Windows",  command=clean_uploads_win).grid(row=R, column=1)
Button(root, text="All",      command=clean_uploads_all).grid(row=R, column=2)

R=R+1
Label(root, text="SMV build dirs:").grid(column=0, row=R, sticky=E)
Button(root, text="Windows",  command=clean_smv_win).grid(row=R, column=1)
Button(root, text="All",      command=clean_smv_all).grid(row=R, column=2)

# ------------------------- Edit ------------------------------

R=R+1
Label(root, text="Edit").grid(column=1, row=R, columnspan=3)

R=R+1
Label(root, text="Release notes:").grid(column=0, row=R, sticky=E)
Button(root, text="Add",      command=add_notes).grid(row=R, column=1)
Button(root, text="Edit",     command=edit_notes).grid(row=R, column=2)
Button(root, text="View",     command=view_notes).grid(row=R, column=3)

R=R+1
Label(root, text="Script:").grid(column=0, row=R, sticky=E)
Button(root, text="Edit",    command=edit_this_page).grid(row=R, column=1)
Button(root, text="Refresh", command=restart_program).grid(row=R, column=2)

R=R+1
Label(root, text="Settings:").grid(column=0, row=R, sticky=E)
Button(root, text="Edit",      command=edit_settings).grid(row=R, column=1)

# ------------------------- Platform labels ------------------------------

R=R+1
Label(root, text="Build libraries/utilities").grid(column=1, row=R, columnspan=3)

R=R+1
Label(root, text="Windows").grid(column=1, row=R)
Label(root, text="Linux").grid(column=2, row=R)
Label(root, text="OSX").grid(column=3, row=R)

# ------------------------- Build libraries ------------------------------

R=R+1
Label(root, text="Libraries:").grid(column=0, row=R, sticky=E)
Button(root, text="Build",     command=partial(build_lib, "windows")).grid(row=R, column=1)
Button(root, text="Build",     command=partial(build_lib, "linux")).grid(row=R, column=2)
Button(root, text="Build",     command=partial(build_lib, "osx")).grid(row=R, column=3)

# ------------------------- Build utilities ------------------------------

R=R+1
Label(root, text="Utilities:").grid(column=0, row=R, sticky=E)
Button(root, text="Build",     command=partial(build_util, "windows")).grid(row=R, column=1)
Button(root, text="Build",     command=partial(build_util, "linux")).grid(row=R, column=2)
Button(root, text="Build",     command=partial(build_util, "osx")).grid(row=R, column=3)

# ------------------------- Build smokeview ------------------------------

R=R+1
Label(root, text="Test Smokeview").grid(column=1, row=R, columnspan=3)

R=R+1
Label(root, text="Windows").grid(column=1, row=R)
Label(root, text="Linux").grid(column=2, row=R)
Label(root, text="OSX").grid(column=3, row=R)

R=R+1
R2=R+1
Label(root, text="Smokeview:").grid(column=0, row=R, sticky=E)
Button(root, text="Build",     command=partial(build_smv, "windows", "test") ).grid(row=R, column=1)
Button(root, text="Build inc", command=build_smv_win_inc).grid(row=R2, column=1)
Button(root, text="Build",     command=partial(build_smv, "linux", "test") ).grid(row=R, column=2)
Button(root, text="Build",     command=partial(build_smv, "osx", "test") ).grid(row=R, column=3)

# ------------------------- bundle smokeview ------------------------------

R=R+2
Label(root, text="Bundle:").grid(column=0, row=R, sticky=E)
Button(root, text="Bundle",     command=partial(bundle_smv, "windows", "test")).grid(row=R, column=1)
Button(root, text="Bundle",     command=partial(bundle_smv, "linux", "test")).grid(row=R, column=2)
Button(root, text="Bundle",     command=partial(bundle_smv, "osx", "test")).grid(row=R, column=3)

# ------------------------- archive smokeview ------------------------------

R=R+1
Button(root, text="Archive",   command=partial(archive_smv, "linux", "test")).grid(row=R, column=2)
Button(root, text="Archive",   command=partial(archive_smv, "osx", "test")).grid(row=R, column=3)

# ------------------------- install smokeview ------------------------------

R=R+1
Label(root, text="Install:").grid(column=0, row=R, sticky=E)
Button(root, text="Install",     command=partial(install_smv, "windows", "test")).grid(row=R, column=1)
Button(root, text="Install",     command=partial(install_smv, "linux", "test")).grid(row=R, column=2)
Button(root, text="Install",     command=partial(install_smv, "osx", "test")).grid(row=R, column=3)

# ------------------------- upload smv bundle ------------------------------

R=R+1
Label(root, text="Upload:").grid(column=0, row=R, sticky=E)
Button(root, text="Upload",     command=upload_bundle).grid(row=R, column=2)
Button(root, text="Copy",       command=copy_bundle).grid(row=R, column=3)

# ------------------------- synchronize ------------------------------

R=R+1
Label(root, text="Sychronize").grid(column=1, row=R, columnspan=2)
R=R+1
Label(root, text="settings:").grid(column=0, row=R, sticky=E)
Button(root, text="==>>smv",     command=webCOPYhome2config).grid(row=R, column=1)
Button(root, text="<<==smv",     command=webCOPYconfig2home).grid(row=R, column=2)


R=R+1
Label(root, text="gsmv/bib:").grid(column=0, row=R, sticky=E)
Button(root, text="fds==>>smv",     command=webSYNCHfds2smv).grid(row=R, column=1)
Button(root, text="fds<<==smv",     command=webSYNCHsmv2fds).grid(row=R, column=2)

root.mainloop()