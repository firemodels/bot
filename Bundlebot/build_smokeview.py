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
webscript_dir  = bot_repo + "Bundlebot\\webscripts\\"

platforms  = ["", "Windows", "Linux", "OSX"]
apps       = ["", "FDS", "Smokeview" ]
guides     = ["", "User", "Verification", "Validation", "Technical"]

version=IntVar()
version.set(1)

platform=IntVar()
platform.set(1)

app=IntVar()
app.set(2)

guide=IntVar()
guide.set(1)

scan_bundle = IntVar(value=1) 

button_width=13

# link windows batch files to python commands

def show_branch():                 os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():                  os.system("start " + webscript_dir + "webSHOW_revisions")

def update_windows():              os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_smv_windows():          os.system("start " + webscript_dir + "webUPDATEwindowsSMVrepos")
def update_all():                  os.system("start " + webscript_dir + "webUPDATErepos")
def update_smv_all():              os.system("start " + webscript_dir + "webUPDATESMVrepos")

def set_revision():                os.system("start " + webscript_dir + "webSET_bundle_revision")

def build_smv_win_inc():           os.system("start " + webscript_dir + "webBUILDsmv Windows testinc")
def build_smv_test_san_deb():      os.system("start " + webscript_dir + "webBUILDsmvdebugsanitize "    + platforms[platform.get()])
def build_smv_test_san_full():     os.system("start " + webscript_dir + "webBUILDsmvsanitize "         + platforms[platform.get()] + " full") 
def build_smv_test_san_inc():      os.system("start " + webscript_dir + "webBUILDsmvsanitize "         + platforms[platform.get()] + " inc")

def build_smz():                   os.system("start " + webscript_dir + "webBUILDsmz  "     + platforms[platform.get()] )

def build_lib():               os.system("start " + webscript_dir + "webBUILDlibs "     + platforms[platform.get()])
def build_util():              os.system("start " + webscript_dir + "webBUILDallprog "  + platforms[platform.get()])
def build_smv():               os.system("start " + webscript_dir + "webBUILDsmv  "     + platforms[platform.get()]  )

def bundle_smv():          os.system("start " + webscript_dir + "webPACKAGEsmv "        + platforms[platform.get()] + " " + str(scan_bundle.get()) )
def install_smv():         os.system("start " + webscript_dir + "webINSTALLsmv "        + platforms[platform.get()]                  )
def upload_bundle():       os.system("start " + webscript_dir + "webUPLOADallsmv "      + platforms[platform.get()])

def bundleinstall_smv():       os.system("start " + webscript_dir + "webPACKAGEINSTALLsmv " + platforms[platform.get()]  )

def download_figures():            os.system("start " + webscript_dir + "webGETfigs "       + apps[app.get()]                 + " " + guides[guide.get()] )
def view_summary():                os.system("start " + webscript_dir + "webVIEWsummary "   + apps[app.get()] )
def build_guides():                os.system("start " + webscript_dir + "webBUILDguides "   + apps[app.get()]                 + " " + guides[guide.get()] )
def view_guides():                 os.system("start " + webscript_dir + "webVIEWguides "    + apps[app.get()]                 + " " + guides[guide.get()] )
 
def archive_smv():                 os.system("start " + webscript_dir + "webARCHIVEAllbundle"  )
def upload_bundle_rel():           os.system("start " + webscript_dir + "webUPLOADsmvrelease")

def webCOPYhome2config():          os.system("start " + webscript_dir + "webCOPYhome2config")
def webCOPYconfig2home():          os.system("start " + webscript_dir + "webCOPYconfig2home")
def webSYNCHfds2smv():             os.system("start " + webscript_dir + "webSYNCHfds2smv")
def webSYNCHsmv2fds():             os.system("start " + webscript_dir + "webSYNCHsmv2fds")

def clean_repos():                 os.system("start " + webscript_dir + "webclean "       + platforms[platform.get()])
def clean_uploads():               os.system("start " + webscript_dir + "webCleanUpload " + platforms[platform.get()])
def clean_smv():                   os.system("start " + webscript_dir + "webCleanSMV "    + platforms[platform.get()])

def set_branch_master():           os.system("start " + webscript_dir + "webSET_branches_master")
def set_branch_devel():            os.system("start " + webscript_dir + "webSET_branches_devel")
def add_notes():                   os.system("start " + webscript_dir + "webGET_smvlog")
def edit_notes():                  os.system("start " + webscript_dir + "webEDIT_release_notes")
def view_notes():                  os.system("start " + webscript_dir + "webVIEW_release_notes")
def edit_this_page():              os.system("start " + webscript_dir + "webEDIT_build_smokeview_py")
def edit_settings():               os.system("start " + webscript_dir + "webEDIT_setup")

root.title('Smokeview')
root.resizable(0, 0)

# ------------------------- Edit ------------------------------

R=0
Label(root, text="---------------------------------SETUP----------------------------------").grid(column=0, row=R, columnspan=4)

R=R+1
Label(root, text="Edit:").grid(column=0, row=R)
Button(root, text="Script",    width=button_width, command=edit_this_page).grid(row=R, column=1)
Button(root, text="Settings",  width=button_width, command=edit_settings).grid(row=R,  column=2)

R=R+1
Label(root, text="Notes:").grid(column=0, row=R)
Button(root, text="Add",      width=button_width, command=add_notes).grid(row=R,      column=1)
Button(root, text="View",     width=button_width, command=view_notes).grid(row=R,     column=2)

# ------------------------- Show repo revisions ------------------------------

R=R+1
Label(root, text="Repos:").grid(column=0, row=R)
Button(root, text="Show Revision",   width=button_width,   command=show_repos).grid(row=R,  column=1)
Button(root, text="Show Branch",     width=button_width,   command=show_branch).grid(row=R, column=2)
Button(root, text="Set all to master",  width=button_width+3, command=set_branch_master).grid(row=R,     column=3)

# ------------------------- Update repos ------------------------------

R=R+1
Label(root, text="Update:").grid(column=0, row=R)
Button(root, text="All repos/All OS's",    width=button_width, command=update_all, bg='blue', fg='white').grid(row=R,     column=1)
Button(root, text="smv/All OS's",    width=button_width, command=update_smv_all).grid(row=R,     column=2)
Button(root, text="All repos/Win",    width=button_width, command=update_windows).grid(row=R, column=3)

# ------------------------- Build ------------------------------

R=R+1
Label(root, text="---------------------------------BUILD----------------------------------").grid(column=0, row=R, columnspan=4)


R=R+1
Radiobutton(root, text="Windows", padx = 0, variable=platform, value=1).grid(row=R, column=0)
Radiobutton(root, text="Linux",   padx = 0, variable=platform, value=2).grid(row=R, column=1)
Radiobutton(root, text="OSX",     padx = 0, variable=platform, value=3).grid(row=R, column=2)

R=R+1
Label(root, text="Clean:").grid(column=0, row=R)
Button(root, text="Repos",   width=button_width, command=clean_repos).grid(row=R,   column=1)
Button(root, text="Uploads", width=button_width, command=clean_uploads).grid(row=R, column=2)
Button(root, text="smv",     width=button_width, command=clean_smv).grid(row=R,     column=3)

R=R+1
Label(root, text="").grid(column=0, row=R, columnspan=4)

R=R+1
Label(root, text="Build:").grid(column=0, row=R)
Button(root, text="Revision",width=button_width, command=set_revision, bg='blue', fg='white').grid(row=R, column=1)
Button(root, text="Libs",              width=button_width, command=build_lib).grid(row=R,  column=2)
Button(root, text="Utils",             width=button_width, command=build_util,bg='blue', fg='white').grid(row=R, column=3)

R=R+1
#Button(root, text="smv dbg sanitize",  width=button_width, command=build_smv_test_san_deb).grid(row=R, column=1)
#Button(root, text="smv sanitize inc",  width=button_width, command=build_smv_test_san_inc).grid(row=R, column=1)
Button(root, text="smv sanitize",      width=button_width, command=build_smv_test_san_full).grid(row=R, column=1)
Button(root, text="smv Win test inc",  width=button_width, command=build_smv_win_inc).grid(row=R,  column=2)
Button(root, text="smv",               width=button_width, command=build_smv, bg='blue', fg='white').grid(row=R,  column=3)

# ------------------------- bundle/install ------------------------------

R=R+1
Button(root, text="Bundle",  width=button_width, command=bundle_smv).grid(row=R,    column=1)
Button(root, text="Upload",  width=button_width, command=upload_bundle).grid(row=R, column=2)
Button(root, text="Install", width=button_width, command=install_smv).grid(row=R,   column=3)
Checkbutton(root, text="Scan bundle", variable=scan_bundle, onvalue=1, offvalue=0).grid(row=R, column=0)

# ------------------------- guides ------------------------------

R=R+1
Label(root, text="---------------------------------GUIDES--------------------------------").grid(column=0, row=R, columnspan=4)

R=R+1
Radiobutton(root, text="FDS",       padx = 0, variable=app, value=1).grid(row=R, column=0)
Radiobutton(root, text="Smokeview", padx = 0, variable=app, value=2).grid(row=R, column=1)

R=R+1
Radiobutton(root, text="User",         padx = 0, variable=guide, value=1).grid(row=R, column=0)
Radiobutton(root, text="Verification", padx = 0, variable=guide, value=2).grid(row=R, column=1)
Radiobutton(root, text="Validation",   padx = 0, variable=guide, value=3).grid(row=R, column=2)
Radiobutton(root, text="Technical",    padx = 0, variable=guide, value=4).grid(row=R, column=3)

R=R+1
Button(root, text="Get Figs",     width=button_width, command=download_figures).grid(row=R, column=0)
Button(root, text="View Summary", width=button_width, command=view_summary).grid(row=R, column=1)
Button(root, text="Build",        width=button_width, command=build_guides).grid(row=R,     column=2)
Button(root, text="View",         width=button_width, command=view_guides).grid(row=R,      column=3)

# ------------------------- synchronize ------------------------------

R=R+1
Label(root, text="----------------------------SYNCHRONIZE----------------------------").grid(column=0, row=R, columnspan=4)
R=R+1
Button(root, text="settings ---> smv",  width=button_width, command=webCOPYhome2config).grid(row=R, column=0)
Button(root, text="settings <--- smv",  width=button_width, command=webCOPYconfig2home).grid(row=R, column=1)
Button(root, text="fds bib ---> smv",   width=button_width, command=webSYNCHfds2smv).grid(row=R,    column=2)
Button(root, text="smv bib ---> fds",   width=button_width, command=webSYNCHsmv2fds).grid(row=R,    column=3, ipadx=3)

root.mainloop()
