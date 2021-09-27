from sys import platform
import sys

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

# link windows batch files to python commands

def show_branch():        os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():         os.system("start " + webscript_dir + "webSHOW_revisions")
def update_windows():     os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_all():         os.system("start " + webscript_dir + "webUPDATErepos")
def set_revision():       os.system("start " + webscript_dir + "webSET_bundle_revision")
def build_smv_win_inc():  os.system("start " + webscript_dir + "webBUILDsmv windows testinc")
def build_smv_win():      os.system("start " + webscript_dir + "webBUILDsmv windows test")
def build_smv_lnx():      os.system("start " + webscript_dir + "webBUILDsmv linux test")
def build_smv_osx():      os.system("start " + webscript_dir + "webBUILDsmv osx test")
def build_lib_win():      os.system("start " + webscript_dir + "webBUILDlibs windows")
def build_lib_lnx():      os.system("start " + webscript_dir + "webBUILDlibs linux")
def build_lib_osx():      os.system("start " + webscript_dir + "webBUILDlibs osx")
def build_util_win():     os.system("start " + webscript_dir + "webBUILDallprog windows")
def build_util_lnx():     os.system("start " + webscript_dir + "webBUILDallprog linux")
def build_util_osx():     os.system("start " + webscript_dir + "webBUILDallprog osx")
def bundle_smv_win():     os.system("start " + webscript_dir + "webPACKAGEsmv windows test")
def bundle_smv_lnx():     os.system("start " + webscript_dir + "webPACKAGEsmv linux test")
def bundle_smv_osx():     os.system("start " + webscript_dir + "webPACKAGEsmv osx test")
def install_smv_win():    os.system("start " + webscript_dir + "webINSTALLsmv windows test")
def install_smv_lnx():    os.system("start " + webscript_dir + "webINSTALLsmv linux test")
def install_smv_osx():    os.system("start " + webscript_dir + "webINSTALLsmv osx test")
def archive_smv_lnx():    os.system("start " + webscript_dir + "webARCHIVEbundle linux test")
def archive_smv_osx():    os.system("start " + webscript_dir + "webARCHIVEbundle osx test")
def upload_bundle():      os.system("start " + webscript_dir + "webUPLOADsmv2git")
def copy_bundle():        os.system("start " + webscript_dir + "webCOPYsmv")
def webCOPYhome2config(): os.system("start " + webscript_dir + "webCOPYhome2config")
def webCOPYconfig2home(): os.system("start " + webscript_dir + "webCOPYconfig2home")
def clean_repos_win():    os.system("start " + webscript_dir + "webclean_win")
def clean_repos_all():    os.system("start " + webscript_dir + "webclean_all")
def clean_uploads_win():  os.system("start " + webscript_dir + "webCleanUploadWin")
def clean_uploads_all():  os.system("start " + webscript_dir + "webCleanUploadAll")
def clean_smv_win():      os.system("start " + webscript_dir + "webCleanWinSMVobjs")
def clean_smv_all():      os.system("start " + webscript_dir + "webCleanSMVobjs")
def set_branch():         os.system("start " + webscript_dir + "webSET_branches")
def add_notes():          os.system("start " + webscript_dir + "webGET_smvlog")
def edit_notes():         os.system("start " + webscript_dir + "webEDIT_release_notes")
def view_notes():         os.system("start " + webscript_dir + "webVIEW_release_notes")
def edit_this_page():     os.system("start " + webscript_dir + "webEDIT_build_smokeview_py")
def edit_settings():      os.system("start " + webscript_dir + "webEDIT_setup")

root.title('Smokeview')
root.resizable(0, 0)

# ------------------------- Show repo revisions ------------------------------

R=0
repos_label = Label(root, text="Repos")
repos_label.grid(column=1, row=R, columnspan=2)

R=R+1
show_label = Label(root, text="Show:")
show_label.grid(column=0, row=R, sticky=E)
b = Button(root, text="Branch",       command=show_branch)
b.grid(row=R, column=1)
c = Button(root, text="Revision",        command=show_repos)
c.grid(row=R, column=2)

# ------------------------- Update repos ------------------------------

R=R+1
update_label = Label(root, text="Update:")
update_label.grid(column=0, row=R, sticky=E)
d = Button(root, text="Windows",    command=update_windows)
d.grid(row=R, column=1)

e = Button(root, text="All",        command=update_all)
e.grid(row=R, column=2)

# ------------------------- Set  ------------------------------

R=R+1
set_label = Label(root, text="Set:")
set_label.grid(column=0, row=R, sticky=E)
f = Button(root, text="Bundle rev",      command=set_revision)
f.grid(row=R, column=1)
f = Button(root, text="Master branch",      command=set_branch)
f.grid(row=R, column=2)

# ------------------------- clean ------------------------------

R=R+1
clean_label = Label(root, text="Clean")
clean_label.grid(column=1, row=R, columnspan=2)
R=R+1
set_clean_repos = Label(root, text="repos:")
set_clean_repos.grid(column=0, row=R, sticky=E)
ee = Button(root, text="Windows",      command=clean_repos_win)
ee.grid(row=R, column=1)
ff = Button(root, text="All",      command=clean_repos_all)
ff.grid(row=R, column=2)

R=R+1
set_clean_uploads = Label(root, text="uploads:")
set_clean_uploads.grid(column=0, row=R, sticky=E)
gg = Button(root, text="Windows",      command=clean_uploads_win)
gg.grid(row=R, column=1)
hh = Button(root, text="All",      command=clean_uploads_all)
hh.grid(row=R, column=2)

R=R+1
set_clean_smv = Label(root, text="SMV build dirs:")
set_clean_smv.grid(column=0, row=R, sticky=E)
ii = Button(root, text="Windows",      command=clean_smv_win)
ii.grid(row=R, column=1)
jj = Button(root, text="All",      command=clean_smv_all)
jj.grid(row=R, column=2)

# ------------------------- Edit ------------------------------

R=R+1
edit_label = Label(root, text="Edit")
edit_label.grid(column=1, row=R, columnspan=3)
R=R+1
release_notes = Label(root, text="Release notes:")
release_notes.grid(column=0, row=R, sticky=E)
aaa = Button(root, text="Add",      command=add_notes)
aaa.grid(row=R, column=1)
bbb = Button(root, text="Edit",      command=edit_notes)
bbb.grid(row=R, column=2)
ccc = Button(root, text="View",      command=view_notes)
ccc.grid(row=R, column=3)

R=R+1
release_notes = Label(root, text="Edit:")
release_notes.grid(column=0, row=R, sticky=E)
ddd = Button(root, text="This script",      command=edit_this_page)
ddd.grid(row=R, column=1)
eee = Button(root, text="Settings",      command=edit_settings)
eee.grid(row=R, column=2)

# ------------------------- Platform labels ------------------------------

R=R+1
build_label = Label(root, text="Build libraries/utilities")
build_label.grid(column=1, row=R, columnspan=3)

R=R+1
windows_label = Label(root, text="Windows")
windows_label.grid(column=1, row=R)
linux_label = Label(root, text="Linux")
linux_label.grid(column=2, row=R)
osx_label = Label(root, text="OSX")
osx_label.grid(column=3, row=R)

# ------------------------- Build libraries ------------------------------

R=R+1
lib_label = Label(root, text="Libraries:")
lib_label.grid(column=0, row=R, sticky=E)
g = Button(root, text="Build",     command=build_lib_win)
g.grid(row=R, column=1)

h = Button(root, text="Build",     command=build_lib_lnx)
h.grid(row=R, column=2)

i = Button(root, text="Build",     command=build_lib_osx)
i.grid(row=R, column=3)

# ------------------------- Build utilities ------------------------------

R=R+1
util_label = Label(root, text="Utilities:")
util_label.grid(column=0, row=R, sticky=E)
j = Button(root, text="Build",     command=build_util_win)
j.grid(row=R, column=1)

k = Button(root, text="Build",     command=build_util_lnx)
k.grid(row=R, column=2)

l = Button(root, text="Build",     command=build_util_osx)
l.grid(row=R, column=3)

# ------------------------- Build smokeview ------------------------------

R=R+1
build2_label = Label(root, text="Test Smokeview")
build2_label.grid(column=1, row=R, columnspan=3)

R=R+1
windows2_label = Label(root, text="Windows")
windows2_label.grid(column=1, row=R)
linux2_label = Label(root, text="Linux")
linux2_label.grid(column=2, row=R)
osx2_label = Label(root, text="OSX")
osx2_label.grid(column=3, row=R)

R=R+1
R2=R+1
smokeview_label = Label(root, text="Smokeview:")
smokeview_label.grid(column=0, row=R, sticky=E)
m = Button(root, text="Build",     command=build_smv_win)
m.grid(row=R, column=1)

n = Button(root, text="Build inc", command=build_smv_win_inc)
n.grid(row=R2, column=1)

o = Button(root, text="Build",   command=build_smv_lnx)
o.grid(row=R, column=2)

p = Button(root, text="Build",     command=build_smv_osx)
p.grid(row=R, column=3)

# ------------------------- bundle smokeview ------------------------------

R=R+2
bundle_label = Label(root, text="Bundle:")
bundle_label.grid(column=0, row=R, sticky=E)
q = Button(root, text="Bundle",     command=bundle_smv_win)
q.grid(row=R, column=1)

r = Button(root, text="Bundle",     command=bundle_smv_lnx)
r.grid(row=R, column=2)

s = Button(root, text="Bundle",     command=bundle_smv_osx)
s.grid(row=R, column=3)

# ------------------------- archive smokeview ------------------------------

R=R+1
t = Button(root, text="Archive",   command=archive_smv_lnx)
t.grid(row=R, column=2)

u = Button(root, text="Archive",     command=archive_smv_osx)
u.grid(row=R, column=3)

# ------------------------- install smokeview ------------------------------

R=R+1
install_label = Label(root, text="Install:")
install_label.grid(column=0, row=R, sticky=E)
v = Button(root, text="Install",     command=install_smv_win)
v.grid(row=R, column=1)
w = Button(root, text="Install",     command=install_smv_lnx)
w.grid(row=R, column=2)
x = Button(root, text="Install",     command=install_smv_osx)
x.grid(row=R, column=3)

# ------------------------- install smokeview ------------------------------

R=R+1
upload_label = Label(root, text="Upload:")
upload_label.grid(column=0, row=R, sticky=E)
y = Button(root, text="Upload",     command=upload_bundle)
y.grid(row=R, column=2)
z = Button(root, text="Copy",       command=copy_bundle)
z.grid(row=R, column=3)

# ------------------------- synchronize ------------------------------

R=R+1
synch_label = Label(root, text="Sychronize")
synch_label.grid(column=1, row=R, columnspan=2)
R=R+1
synch2_label = Label(root, text="settings:")
synch2_label.grid(column=0, row=R, sticky=E)
aa = Button(root, text="==>>smv",     command=webCOPYhome2config)
aa.grid(row=R, column=1)
bb = Button(root, text="<<==smv",     command=webCOPYconfig2home)
bb.grid(row=R, column=2)


R=R+1
gsmv_label = Label(root, text="gsmv/bib:")
gsmv_label.grid(column=0, row=R, sticky=E)
cc = Button(root, text="fds==>>smv",     command=webCOPYhome2config)
cc.grid(row=R, column=1)
dd = Button(root, text="fds<<==smv",     command=webCOPYconfig2home)
dd.grid(row=R, column=2)

root.mainloop()