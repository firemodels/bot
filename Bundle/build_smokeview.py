from tkinter import *
import os

root = Tk()

repo_root = "..\\..\\"
bot_repo = repo_root + "bot\\"
smv_repo = repo_root + "smv\\"
webscript_dir  = bot_repo + "Bundle\\webscripts\\"

def show_branch():    os.system("start " + webscript_dir + "webSHOW_branches")
def show_repos():     os.system("start " + webscript_dir + "webSHOW_revisions")
def update_windows(): os.system("start " + webscript_dir + "webUPDATEwindowsrepos")
def update_all():     os.system("start " + webscript_dir + "webUPDATErepos")
def set_revision():   os.system("start " + webscript_dir + "webSET_bundle_revision")
def build_smv_win_inc():  os.system("start " + webscript_dir + "webBUILDsmv windows testinc")
def build_smv_win():  os.system("start " + webscript_dir + "webBUILDsmv windows test")
def build_smv_lnx():  os.system("start " + webscript_dir + "webBUILDsmv linux test")
def build_smv_osx():  os.system("start " + webscript_dir + "webBUILDsmv osx test")
def build_lib_win():  os.system("start " + webscript_dir + "webBUILDlibs windows")
def build_lib_lnx():  os.system("start " + webscript_dir + "webBUILDlibs linux")
def build_lib_osx():  os.system("start " + webscript_dir + "webBUILDlibs osx")
def build_util_win():  os.system("start " + webscript_dir + "webBUILDallprog windows")
def build_util_lnx():  os.system("start " + webscript_dir + "webBUILDallprog linux")
def build_util_osx():  os.system("start " + webscript_dir + "webBUILDallprog osx")

root.title('Smokeview')
root.resizable(0, 0)

R=0
show_label = Label(root, text="Show:")
show_label.grid(column=0, row=R, sticky=E)
b = Button(root, text="Branch",       command=show_branch)
b.grid(row=R, column=1)
c = Button(root, text="Repos",        command=show_repos)
c.grid(row=R, column=2)

R=1
update_label = Label(root, text="Update:")
update_label.grid(column=0, row=R, sticky=E)
d = Button(root, text="Windows",    command=update_windows)
d.grid(row=R, column=1)

e = Button(root, text="All",        command=update_all)
e.grid(row=1, column=2)

R=2
set_label = Label(root, text="Set:")
set_label.grid(column=0, row=R, sticky=E)
f = Button(root, text="Bundle Revision",      command=set_revision)
f.grid(row=R, column=1)

R=3
windows_label = Label(root, text="Windows")
windows_label.grid(column=1, row=R)
linux_label = Label(root, text="Linux")
linux_label.grid(column=2, row=R)
osx_label = Label(root, text="OSX")
osx_label.grid(column=3, row=R)

R=6
R2=7
smokeview_label = Label(root, text="Smokeview:")
smokeview_label.grid(column=0, row=R, sticky=E)
g = Button(root, text="Build",     command=build_smv_win)
g.grid(row=R, column=1)

h = Button(root, text="Build inc", command=build_smv_win_inc)
h.grid(row=R2, column=1)

i = Button(root, text="Build",   command=build_smv_lnx)
i.grid(row=R, column=2)

j = Button(root, text="Build",     command=build_smv_osx)
j.grid(row=R, column=3)

R=4
lib_label = Label(root, text="Libraries:")
lib_label.grid(column=0, row=R, sticky=E)
k = Button(root, text="Build",     command=build_lib_win)
k.grid(row=R, column=1)

l = Button(root, text="Build",     command=build_lib_lnx)
l.grid(row=R, column=2)

m = Button(root, text="Build",     command=build_lib_osx)
m.grid(row=R, column=3)

R=5
util_label = Label(root, text="Utilities:")
util_label.grid(column=0, row=R, sticky=E)
n = Button(root, text="Build",     command=build_util_win)
n.grid(row=R, column=1)

o = Button(root, text="Build",     command=build_util_lnx)
o.grid(row=R, column=2)

p = Button(root, text="Build",     command=build_util_osx)
p.grid(row=R, column=3)

root.mainloop()