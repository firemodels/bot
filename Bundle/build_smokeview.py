from sys import platform
import sys
from functools import partial
from tkinter import *
import os

if platform != "win32":
  print("***warning: the widgets in this script only run on Windows computers")
#  sys.exit()

root = Tk()

# directory locations

repo_root = os.path.dirname(os.path.realpath(__file__)) + "\\..\\..\\"
bot_repo = repo_root + "bot\\"
smv_repo = repo_root + "smv\\"
webscript_dir  = bot_repo + "Bundle\\webscripts\\"

def restart_program():
    python = sys.executable
    os.execl(python, python, * sys.argv)

platforms = ["", "Windows", "Linux", "OSX"]

v=IntVar()
v.set(1)

w=IntVar()
w.set(1)

button_width=7

# link windows batch files to python commands

def show_branch():                 os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():                  os.system("start " + webscript_dir + "webSHOW_revisions")

def update_windows():              os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_smv_windows():          os.system("start " + webscript_dir + "webUPDATEwindowsSMVrepos")
def update_all():                  os.system("start " + webscript_dir + "webUPDATErepos")
def update_smv_all():              os.system("start " + webscript_dir + "webUPDATESMVrepos")

def set_revision():                os.system("start " + webscript_dir + "webSET_bundle_revision")

def build_smv_win_inc():           os.system("start " + webscript_dir + "webBUILDsmv Windows testinc")
def build_smv():                   os.system("start " + webscript_dir + "webBUILDsmv  "     + platforms[v.get()] + " " + "test" )
def build_smv_gnu():               os.system("start " + webscript_dir + "webBUILDsmv  "     + platforms[v.get()] + "gnu " + "test" )
def build_smv_rel():               os.system("start " + webscript_dir + "webBUILDsmv  "     + platforms[v.get()] + " " + "release" )
def build_lib():                   os.system("start " + webscript_dir + "webBUILDlibs "     + platforms[v.get()])
def build_lib_gnu():               os.system("start " + webscript_dir + "webBUILDlibs "     + platforms[v.get()] + "gnu")
def build_util():                  os.system("start " + webscript_dir + "webBUILDallprog "  + platforms[v.get()])

def bundle_smv():                  os.system("start " + webscript_dir + "webPACKAGEsmv "    + platforms[v.get()] + " " + "test" )
def bundle_smv_rel():              os.system("start " + webscript_dir + "webPACKAGEsmv "    + platforms[v.get()] + " " + "release" )

def install_smv():                 os.system("start " + webscript_dir + "webINSTALLsmv "    + platforms[v.get()] + " " + "test" )
def install_smv_rel():             os.system("start " + webscript_dir + "webINSTALLsmv "    + platforms[v.get()] + " " + "release" )

def archive_smv():                 os.system("start " + webscript_dir + "webARCHIVEAllbundle"  )
def upload_bundle():               os.system("start " + webscript_dir + "webUPLOADsmv2git")
def copy_bundle():                 os.system("start " + webscript_dir + "webCOPYsmv")

def webCOPYhome2config():          os.system("start " + webscript_dir + "webCOPYhome2config")
def webCOPYconfig2home():          os.system("start " + webscript_dir + "webCOPYconfig2home")
def webSYNCHfds2smv():             os.system("start " + webscript_dir + "webSYNCHfds2smv")
def webSYNCHsmv2fds():             os.system("start " + webscript_dir + "webSYNCHsmv2fds")

def clean_repos():                 os.system("start " + webscript_dir + "webclean "       + platforms[w.get()])
def clean_uploads():               os.system("start " + webscript_dir + "webCleanUpload " + platforms[w.get()])
def clean_smv():                   os.system("start " + webscript_dir + "webCleanSMV "    + platforms[w.get()])

def set_branch():                  os.system("start " + webscript_dir + "webSET_branches")
def add_notes():                   os.system("start " + webscript_dir + "webGET_smvlog")
def edit_notes():                  os.system("start " + webscript_dir + "webEDIT_release_notes")
def view_notes():                  os.system("start " + webscript_dir + "webVIEW_release_notes")
def edit_this_page():              os.system("start " + webscript_dir + "webEDIT_build_smokeview_py")
def edit_settings():               os.system("start " + webscript_dir + "webEDIT_setup")

root.title('Smokeview')
root.resizable(0, 0)

# ------------------------- Edit ------------------------------

R=0
Label(root, text="------------Edit------------").grid(column=0, row=R, columnspan=4)

R=R+1
Label(root, text="Notes:").grid(column=0, row=R, sticky=E)
Button(root, text="Add",      width=button_width, command=add_notes).grid(row=R,  column=1)
Button(root, text="View",     width=button_width, command=view_notes).grid(row=R, column=2)

R=R+1
Label(root, text="Edit:").grid(column=0, row=R, sticky=E)
Button(root, text="Script",    width=button_width, command=edit_this_page).grid(row=R, column=1)
Button(root, text="Settings",  width=button_width, command=edit_settings).grid(row=R,  column=2)

# ------------------------- Show repo revisions ------------------------------

R=R+1
Label(root, text="------------Repos------------").grid(column=0, row=R, columnspan=3)

R=R+1
Label(root, text="Show:").grid(column=0, row=R, sticky=E)
Button(root, text="Revision",     width=button_width, command=show_repos).grid(row=R,  column=1)
Button(root, text="Branch",       width=button_width, command=show_branch).grid(row=R, column=2)

# ------------------------- Update repos ------------------------------

R=R+1
Label(root, text="Update fds,smv,...:").grid(column=0, row=R, sticky=E)
Button(root, text="All",        width=button_width, command=update_all).grid(row=R,     column=1)
Button(root, text="Windows",    width=button_width, command=update_windows).grid(row=R, column=2)

# ------------------------- Update repos ------------------------------

R=R+1
Label(root, text="Update smv:").grid(column=0, row=R, sticky=E)
Button(root, text="All",        width=button_width, command=update_smv_all).grid(row=R,     column=1)
Button(root, text="Windows",    width=button_width, command=update_smv_windows).grid(row=R, column=2)

# ------------------------- Set  ------------------------------

R=R+1
Label(root, text="Set:").grid(column=0, row=R, sticky=E)
Button(root, text="Bundle",   width=button_width, command=set_revision).grid(row=R, column=1)
Button(root, text="Master",   width=button_width, command=set_branch).grid(row=R,   column=2)

# ------------------------- clean ------------------------------

R=R+1
Label(root, text="------------Clean------------").grid(column=0, row=R, columnspan=4)

R=R+1

Radiobutton(root, 
               text="Windows",
               padx = 0, 
               variable=w, 
               value=1).grid(row=R, column=0)

Radiobutton(root, 
               text="All",
               padx = 0, 
               variable=w, 
               value=2).grid(row=R, column=1)

R=R+1
Button(root, text="Repos",   width=button_width, command=clean_repos).grid(row=R,   column=0)
Button(root, text="Uploads", width=button_width, command=clean_uploads).grid(row=R, column=1)
Button(root, text="Smv",     width=button_width, command=clean_smv).grid(row=R,     column=2)

# ------------------------- Build/Bundle/Install ------------------------------

R=R+1
Label(root, text="------Build/Bundle/Install------").grid(column=0, row=R, columnspan=3)

R=R+1

Radiobutton(root, 
               text="Windows",
               padx = 0, 
               variable=v, 
               value=1).grid(row=R, column=0)

Radiobutton(root, 
               text="Linux",
               padx = 0, 
               variable=v, 
               value=2).grid(row=R, column=1)

Radiobutton(root, 
               text="OSX",
               padx = 0, 
               variable=v, 
               value=3).grid(row=R, column=2)

# ------------------------- Build libraries, utilities ------------------------------

R=R+1
Label(root,  text="Build/Intel:").grid(column=0, row=R, sticky=E)
Button(root, text="Libs",  width=button_width, command=build_lib).grid(row=R,  column=1)
Button(root, text="Utils", width=button_width, command=build_util).grid(row=R, column=2)

# ------------------------- Build test smokeview ------------------------------
R=R+1
Label(root,  text="Build smv/Intel:").grid(column=0, row=R, sticky=E)
Button(root, text="test",   width=button_width, command=build_smv).grid(row=R,  column=1)
Button(root, text="release",   width=button_width, command=build_smv_rel).grid(row=R,  column=2)
R=R+1
Button(root, text="test inc",    width=button_width, command=build_smv_win_inc).grid(row=R, column=1)

# ------------------------- Build gnu libraries, smokeview ------------------------------

R=R+1
Label(root,  text="Build/GNU:").grid(column=0, row=R, sticky=E)
Button(root, text="Libs",  width=button_width, command=build_lib_gnu).grid(row=R,  column=1)
Button(root, text="smv",   width=button_width, command=build_smv_gnu).grid(row=R,  column=2)

# ------------------------- bundle ------------------------------

R=R+1
Label(root,  text="Bundle:").grid(column=0, row=R, sticky=E)
Button(root, text="test",  width=button_width, command=bundle_smv).grid(row=R,        column=1)
Button(root, text="release",  width=button_width, command=bundle_smv_rel).grid(row=R,        column=2)

# ------------------------- install ------------------------------

R=R+1
Label(root,  text="Install:").grid(column=0, row=R, sticky=E)
Button(root, text="test", width=button_width, command=install_smv).grid(row=R,       column=1)
Button(root, text="release", width=button_width, command=install_smv_rel).grid(row=R,       column=2)

R=R+1
Label(root, text="------Upload/Copy/Archive-------").grid(column=0, row=R, columnspan=3)

R=R+1
Button(root, text="Upload",  width=button_width, command=upload_bundle).grid(row=R, column=0)
Button(root, text="Copy",    width=button_width, command=copy_bundle).grid(row=R,   column=1)
Button(root, text="Archive", width=button_width, command=archive_smv).grid(row=R,   column=2)

# ------------------------- synchronize ------------------------------

R=R+1
Label(root, text="------------Sychronize------------").grid(column=0, row=R, columnspan=3)
R=R+1
Label(root, text="settings:").grid(column=0, row=R, sticky=E)
Button(root, text="->smv",  width=button_width, command=webCOPYhome2config).grid(row=R, column=1)
Button(root, text="<-smv",  width=button_width, command=webCOPYconfig2home).grid(row=R, column=2)


R=R+1
Label(root, text="gsmv/bib:").grid(column=0, row=R, sticky=E)
Button(root, text="fds->smv", width=button_width, command=webSYNCHfds2smv).grid(row=R, column=1)
Button(root, text="fds<-smv", width=button_width, command=webSYNCHsmv2fds).grid(row=R, column=2, ipadx=3)

R=R+1
Button(root, text="Refresh", width=button_width, command=restart_program).grid(row=R, column=0)

root.mainloop()
