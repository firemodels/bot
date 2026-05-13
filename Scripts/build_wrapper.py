from sys import platform
import sys
from functools import partial
from tkinter import *
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

if platform != "win32":
  print("***warning: the widgets in this script only run on Windows computers")
#  sys.exit()

root = Tk()

# directory locations

repo_root = os.path.dirname(os.path.realpath(__file__)) + "\\..\\..\\"
bot_repo = repo_root + "bot\\"
smv_repo = repo_root + "smv\\"
webscript_dir  = bot_repo + "scripts\\webscripts\\"

platforms  = ["", "Windows", "Linux",        "OSX"]
platform=IntVar()
platform.set(1)

apps       = ["", "FDS",     "Smokeview" ]
app=IntVar()
app.set(2)

guides     = ["", "User",    "Verification", "Validation", "Technical"]
guide=IntVar()
guide.set(1)

bots       = ["", "firebot",     "smokebot" ]
bot=IntVar()
bot.set(2)

scan_bundle = IntVar(value=0) 
runall = IntVar(value=1) 

button_width=13

# link windows batch files to python commands

def show_branch():         os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():          os.system("start " + webscript_dir + "webSHOW_revisions")

def update_windows():      os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_smv_windows():  os.system("start " + webscript_dir + "webUPDATEwindowsSMVrepos")
def update_all():          os.system("start " + webscript_dir + "webUPDATErepos")
def update_smv_all():      os.system("start " + webscript_dir + "webUPDATESMVrepos")

def set_revision():        os.system("start " + webscript_dir + "webSET_bundle_revision")

def build_lib():           os.system("start " + webscript_dir + "webBUILDlibs "         + platforms[platform.get()])
def build_util():          os.system("start " + webscript_dir + "webBUILDallprog "      + platforms[platform.get()])
def build_smv():           os.system("start " + webscript_dir + "webBUILDsmv  "         + platforms[platform.get()]  )
def build_smv_inc():       os.system("start " + webscript_dir + "webBUILDsmv  "         + platforms[platform.get()] + " testinc" )

def bld_firebot():         os.system("start " + webscript_dir + "webBuildApps firebot")
def bld_smokebot():        os.system("start " + webscript_dir + "webBuildApps smokebot")

def fullbld_bundle_inst(): os.system("start " + webscript_dir + "webBUILDsmvbundleinst " + platforms[platform.get()] + " test    "  + str(scan_bundle.get()))
def incbld_bundle_inst():  os.system("start " + webscript_dir + "webBUILDsmvbundleinst " + platforms[platform.get()] + " testinc "  + str(scan_bundle.get()))

def bundle_smv():          os.system("start " + webscript_dir + "webPACKAGEsmv "    + platforms[platform.get()] + " " + str(scan_bundle.get()) )
def install_smv():         os.system("start " + webscript_dir + "webINSTALLsmv "    + platforms[platform.get()]                  )
def upload_bundle():       os.system("start " + webscript_dir + "webUPLOADallsmv "  + platforms[platform.get()])

def build_fds():           os.system("start " + webscript_dir + "webBuildFDS ")
def run_fdscases():        os.system("start " + webscript_dir + "webRunFDSCases ")
def make_fdspictures():    os.system("start " + webscript_dir + "webMakeFDSPictures ")
def compare_fdspictures(): os.system("start " + webscript_dir + "webCompareFDSPictures ")

def build_smvapps():       os.system("start " + webscript_dir + "webBuildSmvApps ")
def run_smvcases():        os.system("start " + webscript_dir + "webRunSmvCases ")
def make_smvpictures():    os.system("start " + webscript_dir + "webMakeSmvPictures ")
def compare_smvpictures(): os.system("start " + webscript_dir + "webCompareSmvPictures ")

def build_apps():          os.system("start " + webscript_dir + "webBuildApps "       + bots[bot.get()])
def run_cases():           os.system("start " + webscript_dir + "webRunCases "        + bots[bot.get()] + " " + str(runall.get()))
def check_cases():         os.system("start " + webscript_dir + "webCheckCases "      + bots[bot.get()])
def make_pictures():       os.system("start " + webscript_dir + "webMakePictures "    + bots[bot.get()])
def compare_pictures():    os.system("start " + webscript_dir + "webComparePictures " + bots[bot.get()])

def download_figures():    os.system("start " + webscript_dir + "webGETfigs "       + apps[app.get()]                 + " " + guides[guide.get()] )
def view_summary():        os.system("start " + webscript_dir + "webVIEWsummary "   + apps[app.get()] )
def build_guides():        os.system("start " + webscript_dir + "webBUILDguides "   + apps[app.get()]                 + " " + guides[guide.get()] )
def view_guides():         os.system("start " + webscript_dir + "webVIEWguides "    + apps[app.get()]                 + " " + guides[guide.get()] )
 
def archive_smv():         os.system("start " + webscript_dir + "webARCHIVEAllbundle"  )
def upload_bundle_rel():   os.system("start " + webscript_dir + "webUPLOADsmvrelease")

def webCOPYsettings2smv(): os.system("start " + webscript_dir + "webCOPYsettings2smv")
def webCOPYsmv2settings(): os.system("start " + webscript_dir + "webCOPYsmv2settings")

def set_branch_master():   os.system("start " + webscript_dir + "webSET_branches_master")
def set_branch_devel():    os.system("start " + webscript_dir + "webSET_branches_devel")
def add_notes():           os.system("start " + webscript_dir + "webGET_smvlog")
def edit_notes():          os.system("start " + webscript_dir + "webEDIT_release_notes")
def view_notes():          os.system("start " + webscript_dir + "webVIEW_release_notes")
def edit_this_page():      os.system("start " + webscript_dir + "webEDIT_build_wrapper_py")
def edit_settings():       os.system("start " + webscript_dir + "webEDIT_setup")

root.title('Smokeview')
root.resizable(0, 0)

# ------------------------- Edit ------------------------------

R=0
Label(root, text="---------------------------------SETUP----------------------------------").grid(column=0, row=R, columnspan=4)

R=R+1
Label(root, text="Settings:").grid(column=0, row=R)
Button(root, text="Save",     width=button_width, command=webCOPYsettings2smv).grid(row=R, column=1)
Button(root, text="Restore",  width=button_width, command=webCOPYsmv2settings).grid(row=R, column=2)
Button(root, text="Edit",     width=button_width, command=edit_settings).grid(row=R,       column=3)

R=R+1
Label(root, text="Notes:").grid(column=0, row=R)
Button(root, text="Add",              width=button_width, command=add_notes).grid(row=R,      column=1)
Button(root, text="View",             width=button_width, command=view_notes).grid(row=R,     column=2)
Button(root, text="Edit this script", width=button_width, command=edit_this_page).grid(row=R, column=3)

# ------------------------- Show repo revisions ------------------------------

R=R+1
Label(root, text="Repos:").grid(column=0, row=R)
Button(root, text="Show Revision",      width=button_width, command=show_repos).grid(row=R,        column=1)
Button(root, text="Show Branch",        width=button_width, command=show_branch).grid(row=R,       column=2)
Button(root, text="Set all to master",  width=button_width, command=set_branch_master).grid(row=R, column=3)

# ------------------------- Update repos ------------------------------

R=R+1
Label(root, text="Update:").grid(column=0, row=R)
Button(root, text="All repos/All OS's", width=button_width, command=update_all).grid(row=R,     column=1)
Button(root, text="smv/All OS's",       width=button_width, command=update_smv_all).grid(row=R, column=2)
Button(root, text="All repos/Win",      width=button_width, command=update_windows).grid(row=R, column=3)

# ------------------------- Build ------------------------------

R=R+1
Label(root, text="------------------------------BUILD/BUNDLE------------------------------").grid(column=0, row=R, columnspan=4)


R=R+1
Radiobutton(root, text="Windows", padx = 0, variable=platform, value=1).grid(row=R, column=0)
Radiobutton(root, text="Linux",   padx = 0, variable=platform, value=2).grid(row=R, column=1)
Radiobutton(root, text="OSX",     padx = 0, variable=platform, value=3).grid(row=R, column=2)
Checkbutton(root, text="Scan bundle", variable=scan_bundle, onvalue=1, offvalue=0).grid(row=R, column=3)

R=R+1
Button(root, text="Libs",              width=button_width, command=build_lib).grid(row=R,  column=0)
Button(root, text="Utils",             width=button_width, command=build_util).grid(row=R, column=1)
Button(root, text="smv(full)",         width=button_width, command=build_smv).grid(row=R,  column=2)
Button(root, text="smv(inc)",          width=button_width, command=build_smv_inc).grid(row=R,  column=3)

# ------------------------- bundle/install ------------------------------

R=R+1
Button(root, text="Revision",width=button_width, command=set_revision).grid(row=R,  column=0)
Button(root, text="Bundle",  width=button_width, command=bundle_smv).grid(row=R,    column=1)
Button(root, text="Install", width=button_width, command=install_smv).grid(row=R,   column=2)
Button(root, text="Upload",  width=button_width, command=upload_bundle).grid(row=R, column=3)

R=R+1
Button(root, text="Incremental Build/Bundle/Install",  width=2*button_width+2, command=incbld_bundle_inst).grid(row=R,  column=0, columnspan=2)
Button(root, text="Full Build/Bundle/Install",         width=2*button_width+2, command=fullbld_bundle_inst).grid(row=R, column=2, columnspan=2)

# ------------------------- verification ------------------------------

R=R+1
Label(root, text="---------------------------------VERIFY--------------------------------").grid(column=0, row=R, columnspan=4)
R=R+1
Radiobutton(root, text="firebot",  padx = 0, variable=bot,  value=1).grid(row=R, column=0)
Radiobutton(root, text="smokebot", padx = 0, variable=bot,  value=2).grid(row=R, column=1)
Checkbutton(root, text="run all cases", variable=runall, onvalue=1, offvalue=0).grid(row=R, column=2)
R=R+1
Button(root, text="Run cases",        width=button_width,  command=run_cases).grid(row=R,        column=0)
Button(root, text="Check cases",      width=button_width,  command=check_cases).grid(row=R,      column=1)
Button(root, text="Make pictures",    width=button_width,  command=make_pictures).grid(row=R,    column=2)
Button(root, text="Compare pictures", width=button_width,  command=compare_pictures).grid(row=R, column=3)
R=R+1
Button(root, text="Build fds",            width=button_width, command=bld_firebot).grid(row=R,  column=0)
Button(root, text="Build smokeview, fds2fed",   width=2*button_width+2, command=bld_smokebot).grid(row=R, column=1, columnspan=2)

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
Button(root, text="Build",        width=button_width, command=build_guides).grid(row=R,     column=1)
Button(root, text="View Guide",   width=button_width, command=view_guides).grid(row=R,      column=2)
Button(root, text="View Summary", width=button_width, command=view_summary).grid(row=R,     column=3)

root.mainloop()
