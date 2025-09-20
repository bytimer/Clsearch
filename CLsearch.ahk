#Requires AutoHotkey v2.0 64-bit
#SingleInstance Force

/*
╔══════════════════════════════════════════════════════════════
	CLsearch 为搜索CLaunch中的按钮而生的AHK2脚本，代替它的Ctrl+F查找，支持拼音简拼、全拼搜索
	An alternative tool for the Ctrl+F search function in CLaunch.
	
	v1.0 2025.9.1

CLaunch 优化配置：
	①在 CLaunch 选项/其他：勾选【在相对路径中注册项目】
	②将 CLsearch 文件夹放入 CLaunch.exe 所在文件夹中，最终路径是：CLaunch\CLsearch\CLsearch.exe
		将 CLsearch.exe 拖入 CLaunch 页面中成为按钮
		在 CLaunch 选项/事件: <CLaunch 启动时> 点击【注册】
		添加 CLsearch 所在页面，然后在对应项目列双击选择 CLsearch
		这就是让 CLaunch 启动后自动带起 CLsearch。

	
使用说明：
	全局热键 Win+C 打开搜索窗口，窗口未置顶时失去焦点自动关闭
	在Claunch窗口激活时，按快捷键 Ctrl+F 弹出搜索窗口，可输入文本进行实时搜索。在搜索窗口按Ctrl+F则关闭。
	如果在Claunch中未搜到按钮，按 回车键/Tab键 可用Everything进行搜索，结果也显示在列表控件中。
	搜索窗口失去焦点后会自动关闭。Ctrl+T 可置顶保持不关闭，与点击右上角⛔按钮等同。
	搜索历史保存在 [ 文档\CLsearch\RunLog.ini ]，可手动编辑、删除。
	RunLog.ini 也记录了程序的启动次数，以便在列表框中把次数多的排序在上面。
	用CLaunch当前端界面，添加新标签页，再添加按钮后 从Claunch.ini中复制到CLsearch.ini, 
	这样可以添加不在Claunch界面中显示的自定义按钮项，启动脚本时预先加入全局按钮数组，只在本搜索框中可被搜到。

	Enter回车键：焦点在输入框时，聚焦到列表控件；焦点在列表控件时，启动当前项 (优先级：光标下的行>选中行>焦点行)。
	Tab键：焦点在输入框时，聚焦到列表控件；焦点在列表控件时，切换焦点到输入框。
	Space空格键：焦点在列表控件时，启动当前项。
	Backspace / Ctrl+大写 / Ctrl+Enter / 鼠标右键：焦点在列表控件时，打开当前项可执行文件所在路径。
	Alt+1~9,0: 启动前9项，末项。
	数字键1~9,0: 焦点在列表控件时，聚焦前9项/末项，并选中；空格键启动当前项。
	W / S / A / D：焦点在列表控件时，上/下左/右移动。
	Home / End： 常规响应。
	F2/Up / F3/Down：上移选择/下移选择
	F4 / Shift+Tab：弹出搜索历史下拉选择框。
	F5：强制用ev重新搜索，刷新列表。
	F6 / Shift+Enter::{ ; 从exe路径获取exe文件名，输入到编辑框，用于按F5强制Everything搜索全盘
	光标在列表控件中移动时，上下键切换焦点行时，都会显示对应项按钮的提示文本，可指示当前项在Claunch页面中的按钮位置。
	列表控件行的提示文本显示出来时，按 Ctrl+C 可复制提示文本。
	` 键(数字1左边)：Button按钮的提示文本中如果含有<http(s)://网址>，将被视为官网，直接打开。

	其他：
	 从btn.exePath 匹配到网址 (如 chrome.exe http://xxxx ) ，右键则打开网址
	 Ev搜索时排除回收站
	 窗口拉伸大小时，列表框自动舒展适配
	 点击窗口背景层拖动，可移动窗口

	待完善：
	 ListView 拖拽选中行 可将ev搜到的文件拖到Claunch来添加按钮 (难以实现，但可以右键列表行 打开所在文件夹后 拖拽文件)
	 检测是否存在横向滚动条，以调整窗口高度 https://www.autohotkey.com/boards/viewtopic.php?t=126573
	 需要给Claunch提需求，增加首选网址字段、启动次数记录字段、上次启动时间字段
	 光标下的列表控件行背景色 非焦点时选中行的背景色不够深 交错行背景色 列标题背景色 https://www.autohotkey.com/boards/viewtopic.php?t=113921 
	 gui用resize时状态栏右下角拉伸控件SBARS_SIZEGRIP范围的背景色不一致bug (用选项近似解决 "+0x3 -0x100") https://www.autohotkey.com/board/topic/23964-statusbar-background-problem-solved-windows-bug/
	 ListView 深色控件类 需要v2.1 beta9 https://github.com/nperovic/DarkThemeListView  https://www.autohotkey.com/boards/viewtopic.php?f=83&t=128572
╚══════════════════════════════════════════════════════════════
*/
	
;DetectHiddenWindows True
InstallKeybdHook
InstallMouseHook
;Persistent

;══════════════════════════════════════════════════{{{1

#Include Lib\ToolTipOptions.ahk ; 更美观的提示条 https://www.autohotkey.com/boards/viewtopic.php?f=83&t=113308
#Include Lib\IbPinyin.ahk  ; 拼音匹配库 ib-pinyin-ahk2 IbPinyinLib https://github.com/Chaoses-Ib/ib-matcher
;#DllLoad Lib\Everything64.dll
#Include Lib\Everything.ahk


;══════════════════════════════════════════════════{{{1

ToolTipOptions.Init() ; 提示条美化
ToolTipOptions.SetFont("s10" , "Microsoft YaHei") ; Consolas
ToolTipOptions.SetColors("F2F2D7", "000000") ; 黄底白字

tipText := "CLsearch  搜索CLaunch中的按钮"
tipText .= "`n若不存在则用Everything搜索可执行程序"
tipText .= "`nAutoHotkey v" A_AhkVersion
A_IconTip := tipText ; 托盘图标提示内容

CLsearch_ini := A_ScriptDir "\CLsearch.ini"
;RunLogIni := A_ScriptDir "\RunLog.ini" ; 记录搜索历史，程序的启动次数
RunLogIni := A_MyDocuments "\CLsearch\RunLog.ini" ; 记录搜索历史，程序的启动次数
CLfolder := A_ScriptDir "\.." ; Claunch.exe所在文件夹
CLini := CLfolder "\Data\CLaunch.ini"

RunLogMap := Map()
Buttons := []
GV_Gui_Hwnd := 0
GV_LV_Hwnd := 0
GV_btnTop_Hwnd := 0
GV_CopyTipText := ""
GV_CloseOnLoseFocus := true
GV_SelectIndex := -1 ; Alt+0~9组合键 所按的数字键
GV_GoWebsite := 0 ; 按键标识 ` 
GV_F5 := 0 ; 按键标识 F5
GV_SearchHistoryN := 10 ; 搜索历史记录的最大条数
GV_SearchHistoryArr := []

;════托盘菜单开始══════════════════════════════════════════════════{{{1
;如果用#NoTrayIcon 隐藏了托盘图标, 则改变图标不会让它显示出来; 要让它显示, 请使用 A_IconHidden := false
;A_IconHidden := false

tray := A_TrayMenu
tray.Delete()
;tray.ADD() ;添加分隔线-----------------------
tray.ADD("打开自身路径(&F)", Menu_ShowFile)
tray.ADD("暂停热键(&S)", Menu_Suspend)
tray.ADD("暂停脚本(&A)", Menu_Pause)
tray.ADD("重启脚本(&R)", Menu_Reload)
tray.ADD("退出(&X)", Menu_Exit)
tray.ClickCount := 1

Menu_ShowFile(*){
	ShowFileInFoler(A_ScriptFullPath)
}
Menu_Suspend(*){
	ForceKeysUp()
	Suspend
	tray.ToggleCheck("暂停热键(&S)")
}
Menu_Pause(*){
	ForceKeysUp()
	if A_IsPaused {
		Suspend 0
		Pause 0
		tray.Uncheck("暂停热键(&S)")
	} else {
		Suspend 1
		Pause 1
		tray.Check("暂停热键(&S)")
	}
	;Pause -1
	tray.ToggleCheck("暂停脚本(&A)")
}
Menu_Reload(*){
	ForceKeysUp()
	Reload
}
Menu_Exit(*){
	ForceKeysUp()
	ExitApp
}
;防卡键
ForceKeysUp(){
	Send "{space up}"
	Send "{capslock up}"

	Send "{LWin Up}"
	Send "{RWin Up}"

	Send "{Shift Up}"
	Send "{LShift Up}"
	Send "{RShift Up}"

	Send "{Alt Up}"
	Send "{LAlt Up}"
	Send "{RAlt Up}"

	Send "{Control Up}"
	Send "{LControl Up}"
	Send "{RControl Up}"

	Send "{Volume_Down Up}"
	Send "{Volume_Up Up}"
	
	Sleep 300 
	;Reload
	;ExitApp
}

;════托盘菜单结束══════════════════════════════════════════════════{{{1

;════读取配置添加按钮 开始════════════════════════════════════════════{{{1
if ProcessExist("Claunch.exe") {
	CLaunchPath := ProcessGetPath("Claunch.exe")
	SplitPath CLaunchPath, , &CLfolder
	CLini := CLfolder "\Data\CLaunch.ini"
	CLsearch_ini := CLfolder "\CLsearch\CLsearch.ini"
	RunLogIni := CLfolder "\CLsearch\RunLog.ini"
}

ReadRunLog(RunLogIni)
AddButtons(CLsearch_ini)
AddButtons(CLini)

ReadRunLog(iniPath){
	if !FileExist(iniPath)
		return

	RunLogText := IniRead(iniPath, "RunLog", , "") ; 读取整个章节
	if RunLogText {
		Loop Parse, RunLogText, "`n", "`r" {
			if InStr(A_LoopField, "=") = 0
				Continue
			tempArr :=StrSplit(A_LoopField, "=")
			if Trim(tempArr[2]) = ""
				Continue
			
			RunLogMap[tempArr[1]] := tempArr[2]
		}
	}
	;msgbox RunLogMap.Count
}

AddButtons(iniPath){
	if !FileExist(iniPath)
		return
	
	btn := {}
	tabPage := ""
	SubMenuPos := ""
	isPage := false
	isButton := false
	SubMenuIdxMap := Map()
	btnN := 0
	
	if FileExist(iniPath) {
		Loop read, iniPath
		{
			if RegExMatch(A_LoopReadLine, "i)^\[SubMenu(\d+)\]", &SubIdx) { ; 是子菜单节点
				isPage := false
				isButton := false
				SubMenuPos := SubMenuIdxMap[String(Number(SubIdx[1]))] ; 映射子菜单所在哪个标签页的哪个按钮位置
				Continue
			}

			if RegExMatch(A_LoopReadLine, "i)^\[Page(\d+)\]", &pg) { ; 是标签页节点
				isPage := true
				isButton := false

				if pg[1] = "999"
					tabPage := "CLsearch.ini"
				else
					tabPage := "Page" (pg[1]+1)

				Continue
			}
			;if InStr(A_LoopReadLine, "[Btn") = 1 {
			if RegExMatch(A_LoopReadLine, "i)^\[Btn(\d+)\]") { ; 碰到新的按钮节点
			;if RegExMatch(A_LoopReadLine, "i)^\[Btn(\d+)\]", &btnN) {
				;msgbox "btnPos: " btnN[1] ; 按钮在其标签页中是第几个被添加的
				;btnPos := btnN[1]
				isPage := false
				isButton := true
				if btn.HasOwnProp("File") ; 实际上每个 [BtnXXX] 节点都有空行分隔，这里不会执行
					Buttons.Push(btn)
				btn := {} ; 释放旧对象，新对象 接收下一个btn的属性
				Continue
			}

			if !isButton && !isPage
				Continue
		
			if InStr(A_LoopReadLine, "=") = 0 { ; 碰到空行 (这里 CLsearch.ini 是以空行分隔每个button节点的，最后也需要有个空行)
				if btn.HasOwnProp("File") && Trim(btn.File) != "" { ; 只将有可执行文件的按钮加入数组 (CLaunch注册的特殊组件如控制面板、网络连接、启动、微软商店 无可执行文件，这种则不加入)
					btn.searchField := btn.Name '`t' btn.File '`t' btn.Parameter '`t' btn.Directory '`t' btn.Tip ; 先合并 用于后面简化匹配过滤
					
					btn.RunLogKey := btn.File ; 用于记录启动次数
					if btn.Parameter != ""
						btn.RunLogKey .= '`t' btn.Parameter ; 原始的文件+参数，可以标识一个按钮
					
					; 相对路径转换为绝对路径 针对File和Directory属性
					if IsRelativePath(btn.Directory) ; 相对路径
						btn.Directory := GetFullPathName(CLfolder "\" btn.Directory) ; 转为绝对路径
					if IsRelativePath(btn.File) ; 相对路径
						btn.File := GetFullPathName(CLfolder "\" btn.File) ; 转为绝对路径
					
					btn.exePath := btn.File ; 用于打开exe的路径
					if btn.File = "%ComSpec%" || btn.File = "C:\Windows\System32\cmd.exe" { ; 调用cmd的按钮
						;if RegExMatch(btn.Parameter, "i)\s`"?([^\(]+\.exe)", &exeName) { ; cmd.exe 参数 /K 调用的相对路径exe
						if RegExMatch(btn.Parameter, 'i)([^" &\(\)\^=;,]+\.exe|".+\.exe")', &exeName) { ; cmd.exe 参数 /K 调用的相对路径exe （注意：参数必须要双引号包裹 若文件名含有这些特殊字符：空格 &()[]{}^=;!'+,`~
							if IsRelativePath(exeName[1])
								btn.exePath := RegExReplace(btn.Directory, "\\+$") "\" Trim(exeName[1], '"') ; 获取cmd调用的exe的完整路径 (如果exe文件名有双引号，先去掉)
							else
								btn.exePath := Trim(exeName[1], '"') ; 绝对路径，直接赋值
						}
					} else if RegExMatch(btn.Parameter, "i)^(f|ht)tps?:\/\/") { ; 参数是网址，exe是浏览器，前面加上浏览器的exe名
							btn.RunLogKey := btn.Parameter
							SplitPath btn.File, &oName 
							btn.exePath := oName ' ' btn.Parameter
					}
					
					;if btn.Tip = ""
						;btn.Tip := btn.exePath
					if !btn.HasOwnProp("Position") ; 子菜单中的按钮节点 没有Position，这里补上
						btn.Position := SubMenuPos
						
					Buttons.Push(btn)
				}
				btn := {} ; 释放旧对象，新对象 接收下一个btn的属性
				Continue
			}
			
			temp := StrSplit(A_LoopReadLine, "=", , 2) ; 仅分割为两部分
			;if Trim(temp[2]) = "" ; 有Key 无Value 跳过
				;Continue

			Switch Trim(temp[1])
			{
				Case "Position": 
					btn.Position := tabPage " → " (temp[2]+1)

				;以下是对 Button 类型代码的解析，不尽正确，但差不多
				; Type=40000001 Type=e0410001
				; 第1位 =0 都没勾选，0+4则勾选了【不更新图标】，值+2 则勾选了【右键点击时显示外壳菜单】，值+8 则是Ctrl+右键点击后给按钮加锁了(Shift+右键可现实CL内部菜单)，三项都勾选则为2+4+8=e
				; 第3位 权限级别 =0是默认，=2是标准用户，=4是管理员
				; 第4位 程序已运行时的操作：=0 默认，=1 激活，=2 关闭
				; 第5位 =0是普通文件，=2是系统shell类特殊文件夹(如控制面板、此电脑、我的文档等)，=4是CLaunch内部功能、关机、注销等；=2时：第8位为3 控制面板，为7 启动，为8 启动，
				; 第7位 =0 是按钮，=1 是子菜单；
				; 第8位 =1是可执行文件，=2非可执行文件，=4是网址链接；=3时 第5位为2代表控制面板，为6 网络连接
				Case "Type":
					;btn.Type := SubStr(temp[2], 7, 1) = "1" ? "SubMenu" : "Button"
					tmpArr := StrSplit(temp[2])
					btn.Type := tmpArr[7] = "1" ? "SubMenu" : "Button"
					btn.asAdmin := tmpArr[3] = "4" ? true : false
				Case "Name": 
					;if !btn.HasOwnProp("Name")
					if isPage
						tabPage .= " [" temp[2] "]"
					else
						btn.Name := temp[2]
				Case "File": 
					;if !btn.HasOwnProp("File")
						btn.File := temp[2]
				Case "Parameter": 
						btn.Parameter := Trim(temp[2])
				Case "Directory": 
						btn.Directory := temp[2]
				Case "Tip": 
						btn.Tip := temp[2]
				Case "SubMenuIdx": 
					SubMenuIdxMap[temp[2]] := btn.Position "  | 子菜单：" btn.Name

				;WindowStat=1 正常，=7 窗口最小化, =3 窗口最大化
				;Flag=00000020 优先级 正常，=00000100 实时，=00000080 高，=00000040 低，=00008000 高于正常，=00004000 低于正常
			}
		}
		
		;n := 9
		;MsgBox "按钮个数: " Buttons.length "`n按钮：" Buttons[n].Position "`nName: " Buttons[n].Name "`nFile: " Buttons[n].exePath "`nParameter: " Buttons[n].Parameter "`nDirectory: " Buttons[n].Directory " `nTip: " Buttons[n].Tip
	}
}

/*
; 用于核对读取到的按钮详情 与CLaunch.ini比对测试
for butn in Buttons {
	if butn.Parameter = "<clipboard>"
		a := ""
	FileAppend("`n" butn.Position "  " butn.Type "  " butn.Name "  " butn.exePath, CLfolder "\aaa.txt")
}
*/
	
;════读取配置添加按钮 结束════════════════════════════════════════════{{{1

;════热键定义开始══════════════════════════════════════════════════{{{1

#HotIf WinActive("Search Buttons In CLaunch ahk_class AutoHotkeyGUI")
^f::WinClose ; 关闭搜索窗口
^c::{ ; 复制提示文本   注意：必须激活CLsearch窗口，且显示了提示信息，才能复制到
	if GV_CopyTipText != ""
		A_Clipboard := GV_CopyTipText
	else
		SendInput "^c"
}

space::{ ; 焦点在列表控件时，空格打开选定项
	global GV_F5 := 0
	if FocusClassNN() = "SysListView321"
		Send "{enter}"
	else
		Send "{space}"
}

`::{ ; 打开提示文本中的网址，标识为<http(s)://xxxxxxxxxxxxx>，即第一串以<>闭包的网址被视作官网
	global GV_GoWebsite := 1, GV_F5 := 0
	SendInput "{enter}"
}

tab::{
	global GV_F5 := 0
	if !ControlGetVisible("SysListView321") ; ListView不可见时 执行默认按钮 搜索
		SendInput "{enter}"
	else
		SendInput "{tab}"
}

f5::{ ; 强制用ev重新搜索输入框中的文本 刷新列表
	global GV_F5 := 1
	SendInput "{enter}"
}

f4::
+tab::{ ; 下拉组合编辑框弹出列表菜单
	ControlFocus "ComboBox1", "A" 
	;PostMessage(0x014F, 1, 0, ControlGetHwnd("ComboBox1", "A"))
	ControlShowDropDown "ComboBox1"
}

backspace::
^capslock::
^enter::{ ; 打开所在文件夹
	ctrlHwnd := ControlGetFocus("A")
	if !ctrlHwnd
		return
	GuiCtrl := GuiCtrlFromHwnd(ctrlHwnd)
	if GuiCtrl.Name = "ButtonsList" { ; ListView控件
		rowN := GuiCtrl.GetNext() ; C 下一个选中的行，F 焦点行, 无参则光标下高亮的行
		if (rowN = 0)
			return
		exeFile := GuiCtrl.GetText(rowN, 3) ; 获取第3列文本 Path
		if !RegExMatch(exeFile, "i)^(ftp|https?):\/\/") ; 如果是未指定浏览器的网址
			exeFile := EnvDeref(exeFile)
		ShowFileInFoler(exeFile)
	} else if A_ThisHotkey = "backspace"
		SendInput "{backspace}"
	else
		ControlFocus "SysListView321"
}

F6::
+enter::{ ; 从exe路径获取exe文件名，输入到编辑框，用于按F5强制Everything搜索全盘
	global GV_LV_Hwnd
	if GV_LV_Hwnd {
		GuiCtrl := GuiCtrlFromHwnd(GV_LV_Hwnd)
		rowN := GuiCtrl.GetNext()
		if (rowN = 0)
			return
		exeFile := GuiCtrl.GetText(rowN, 3) ; 程序路径
		SplitPath exeFile, &exeName
		ControlSetText exeName, "ComboBox1"
	}
}

^t::{
	; 此方式似不能触发按钮的Click事件回调
	;ControlClick GV_btnTop_Hwnd, "A" ; 点击置顶按钮 (ControlClick对隐藏按钮无效)

	global GV_CloseOnLoseFocus := !GV_CloseOnLoseFocus
	WinSetAlwaysOnTop -1, "A"
	btnText := GV_CloseOnLoseFocus ? "⛔" : "☑"
	;btnToggleTop := GuiCtrlFromHwnd(GV_btnTop_Hwnd)
	;btnToggleTop.Text := btnText
	ControlSetText btnText, "Button1"
}

f3::
down::{ ; 焦点从编辑框下移到ListViewk控件 (当ComboBox弹出下拉列表时，发送下方向键)
	DroppedList := SendMessage(0x0157, 0, 0, ControlGetHwnd("ComboBox1", "A")) ; 返回值非零表示下拉列表已弹出
	if DroppedList {
		Send "{down}"
	} else if ControlGetVisible("SysListView321") { ; 如果列表控件可见
		if FocusClassNN() = "SysListView321" { ; 如果当前焦点在列表
			global GV_LV_Hwnd
			GuiCtrl := GuiCtrlFromHwnd(GV_LV_Hwnd)
			row := GuiCtrl.GetCount()
			if GuiCtrl.GetNext(, "F") = row ; 判断焦点在最后一行
				Send "{home}"
			else
				Send "{down}"
		} else {
			ControlFocus "SysListView321"
			;ControlChooseIndex 1, "SysListView321", "A" ; 选择第一行
		}
	} else
		Send "{down}"
}

f2::
up::{ ; 焦点从编辑框下移到ListViewk控件，选中最后一行 (当ComboBox弹出下拉列表时，发送上方向键)
	DroppedList := SendMessage(0x0157, 0, 0, ControlGetHwnd("ComboBox1", "A")) ; 返回值非零表示下拉列表已弹出
	if DroppedList {
		Send "{up}"
	} else if ControlGetVisible("SysListView321") { ; 如果列表控件可见
		global GV_LV_Hwnd
		GuiCtrl := GuiCtrlFromHwnd(GV_LV_Hwnd)
		if FocusClassNN() = "SysListView321" { ; 如果当前焦点在列表
			if GuiCtrl.GetNext(, "F") = 1 ; 判断焦点在第一行
				Send "{end}"
			else
				Send "{up}"
		} else {
			row := GuiCtrl.GetCount()
			GuiCtrl.Focus()
			GuiCtrl.Modify(row, "Focus Select Vis") ; 选中最后一行
		}
	} else
		Send "{up}"
}

w::{
	if FocusClassNN() = "SysListView321" { ; 当焦点在列表控件时
		global GV_LV_Hwnd
		GuiCtrl := GuiCtrlFromHwnd(GV_LV_Hwnd)
		if GuiCtrl.GetNext(, "F") = 1 ; 判断焦点在第一行
			Send "{end}"
		else
			Send "{up}"
	} else
		SendInput A_ThisHotkey

}
s::{
	if FocusClassNN() = "SysListView321" { ; 当焦点在列表控件时
		global GV_LV_Hwnd
		GuiCtrl := GuiCtrlFromHwnd(GV_LV_Hwnd)
		row := GuiCtrl.GetCount()
		if GuiCtrl.GetNext(, "F") = row ; 判断焦点在最后一行
			Send "{home}"
		else
			Send "{down}"
	} else
		SendInput A_ThisHotkey

}
a::{
	if FocusClassNN() = "SysListView321" ; 当焦点在列表控件时
		SendInput "{left}"
	else
		SendInput A_ThisHotkey

}
d::{
	if FocusClassNN() = "SysListView321" ; 当焦点在列表控件时
		SendInput "{right}"
	else
		SendInput A_ThisHotkey

}

1::
2::
3::
4::
5::
6::
7::
8::
9::
0::{
	global GV_LV_Hwnd
	ctrlHwnd := ControlGetFocus("A")
	if ctrlHwnd && ctrlHwnd = GV_LV_Hwnd { ; 焦点在列表控件时
		GuiCtrl := GuiCtrlFromHwnd(ctrlHwnd)
		row := A_ThisHotkey
		if row = "0"
			row := GuiCtrl.GetCount()
		GuiCtrl.Modify(row, "Focus Select Vis")
	} else 
		SendInput A_ThisHotkey
}

!1::
!2::
!3::
!4::
!5::
!6::
!7::
!8::
!9::
!0::{ ; 启动对应行的程序
	global GV_F5 := 0
	global GV_SelectIndex := Number(SubStr(A_ThisHotkey, 2))
	;DetectHiddenWindows True
	;SetControlDelay -1
	SendInput "{enter}"
}
#HotIf

;════热键定义完毕══════════════════════════════════════════════════{{{1


;════主体功能窗口 开始══════════════════════════════════════════════════{{{1

; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=14205 ListView列表控件过滤

#c::SearchGuiShow(1) ; 全局 居中显示

#HotIf WinActive("ahk_class CLaunchWndClass")
^f::SearchGuiShow()
#HotIf

SearchGuiShow(pCenter:=0){
	global GV_Gui_Hwnd, GV_LV_Hwnd, GV_btnTop_Hwnd, GV_CopyTipText, GV_CloseOnLoseFocus, GV_SelectIndex, GV_GoWebsite, GV_F5, RunLogIni, GV_SearchHistoryN, GV_SearchHistoryArr, RunLogMap
	if WinExist("Search Buttons In CLaunch ahk_class AutoHotkeyGUI")
		WinClose
	if GV_Gui_Hwnd {
		prevGui := GuiFromHwnd(GV_Gui_Hwnd)
		prevGui.Destroy()
		return
	}
	if !FileExist(RunLogIni)
		FileAppend "[SearchHistory]", RunLogIni, "UTF-16"
	
	if pCenter {
		OwnWin := ""
		showPos := "Center"
	} else {
		OwnWin := "+Owner" WinExist("A")
		WinGetPos &OutX, &OutY ; &OutWidth, &OutHeight
		showPos := "X" OutX+80 " Y" OutY+160
		Sleep 200  ; 打开CLaunch窗口后 极短时间内执行窗口Show()，弹出的窗口会因被CL主窗口抢夺焦点而关闭，故须在前面增加延迟
	}
	
	LineCount := 20 ; 列表限制20行，超过则出现滚动条
	BgColor := "C0D0B9" ; "AFBFAA" "b8C6b5" "bfcebd" "CED9CD" "C4D5BE" "B5B5B5"
	color := "F3F5F2" ; "DCE0DE" "D4D0C8"  - gray normal msgbox
	initStatus := false ; 初始化状态标志
	GV_CloseOnLoseFocus := true
	
	; GUI Options:  +Resize 允许调整大小，-Caption 去掉标题栏, +AlwaysOnTop 置顶
	MyGui := Gui("-Caption +MinSize +Border +Resize -MinimizeBox -MaximizeBox +ToolWindow " OwnWin, "Search Buttons In CLaunch") ; 
	GV_Gui_Hwnd := MyGui.Hwnd
	MyGui.MarginX := 6 ; 左右边距
	MyGui.MarginY := 6 ; 上下边距
	MyGui.BackColor := BgColor ; 窗口背景色
	MyGui.SetFont("s10 cBlack", "Microsoft YaHei") ; 字体设置

	;EditCtrl := MyGui.AddEdit("w670 BackgroundF0F0F0")
	;EditCtrl.OnEvent("Change", Search)  ; 绑定文本改变事件
	ComBox := MyGui.AddComboBox("w670 BackgroundF0F0F0") ; 改用下拉组合编辑框，可以载入搜索历史
	ComBox.OnEvent("Focus", (*)=>ToolTip())  ; 聚焦时关闭提示信息
	ComBox.OnEvent("Change", Search)  ; 绑定文本改变事件
	;初始化添加历史记录选择列表，并选择第一条 当控件失去焦点或按Enter后 记录当前搜索文本到历史 窗口关闭时记录到历史
 	if FillComBox(ComBox) > 0
 		ComBox.Choose(1) ; 选择第一项
 	ComBox.OnEvent("LoseFocus", AddToHistory) ; 失去焦点时记录历史
 	
	btnToggleTop := MyGui.Add("Button", "-Tabstop x+6 yp+0 w24 HP vKeepTop", "⛔") ; "T"
	btnToggleTop.ToolTip := "置顶，失去焦点时不自动关闭 (Ctrl+T)"
	btnToggleTop.OnEvent("Click", ToggleTop) ; 绑定单击事件
	GV_btnTop_Hwnd := btnToggleTop.Hwnd
	
	;LV := MyGui.AddListView("Hidden -Multi cBlack Grid R1 W700 Background" color, ["名称", "路径", "提示文本", "文件", "参数", "工作文件夹"])
	LV := MyGui.AddListView("LV0x8000 +Report Hidden -Multi vButtonsList cBlack Grid R1 W700 XM Background" color, ["数组索引", "按钮位置", "程序路径", "启动次数", "行", "名称", "提示文本"])
	GV_LV_Hwnd := LV.Hwnd
	LV_GridColor(LV, 0x787878) ; 更改 Grid表格线的颜色
	;LV.InsertCol:("FileName")  ; 添加第一列
	;LV.OnEvent("DoubleClick", LVRun)  ; 绑定双击事件 事件列表:https://wyagd001.github.io/v2/docs/lib/GuiOnEvent.htm#Events
	LV.OnEvent("Click", LVRun) ; 单击事件
	LV.OnEvent("ItemFocus", LVTip) ; 焦点变化事件
	LV.OnEvent("ContextMenu", LVGoPath) ; 右键单击事件
	;LV.OnNotify(-109, LVN_BEGINDRAG) ; 鼠标拖拽事件
	;LV.OnNotify(-121, WM_NOTIFY) ; 消息通知    https://www.autohotkey.com/board/topic/79703-super-global-gui-constants/page-2
	; LVN_HOTTRACK = -121 鼠标移到项上时，由列表视图控件发送
	; LV.OnNotify(-13, NM_HOVER) ; 鼠标悬停在列表视图控件上
	; https://geekdude.io/static/ahk/Constants.W32.ini
	; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=4557  Notify 通知消息号

	; https://www.autohotkey.com/boards/viewtopic.php?t=115218
	btnDefault := MyGui.Add("Button", "Default -Tabstop x+0 yp+0 w0 h0 Hidden1 vOK", "OK")
	btnDefault.OnEvent("Click", DefaultAction) ; 隐藏按钮 按Enter激活列表控件/执行选中项
	
	; 创建隐藏的ListView控件，用于计算ListView的行高，以自动设置窗口大小
	LV2 := MyGui.Add("ListView", "-Tabstop Hidden1 grid r2", ["test"])
	LV.GetPos(,,, &hgt1)
	LV2.GetPos(,,, &hgt2)
	RowHeight := hgt2 - hgt1
	LV_HeaderH := hgt1 - RowHeight ; 列标题行的高度
	;EditCtrl.GetPos(,,, &editHgt)
	ComBox.GetPos(,,, &editHgt)
	
	TotalItems := Buttons.Length	
	LV.ModifyCol(1, "0 Integer")
	LV.ModifyCol(2, 0)
	LV.ModifyCol(3, 0)
	LV.ModifyCol(4, "0 Integer") ; 前4列隐藏
	LV.ModifyCol(5, "Auto Integer Right") ; Integer标示此列为数值类型，按数值排序而非文本
	LV.ModifyCol(6, 200)
	LV.ModifyCol(7, "AutoHdr")
	
	StaBar := MyGui.AddStatusBar("-Tabstop -Theme +0x3 -0x100 Background" BgColor, "   " TotalItems " / 共 " TotalItems " 项  在CLaunch中")
	StaBar.GetPos(,,, &sbarHgt)
	
	MyGui.OnEvent("Close", CloseMyGui)
	MyGui.OnEvent("Escape", CloseMyGui)
	MyGui.OnEvent("Size", Gui_Size) ; 根据窗口大小自动调整ListView宽度  (有副作用 会搞乱界面)
	
	MyGui.Show("AutoSize W700 H700 " showPos)

	; 监听左键按下消息 拖移窗口
	OnMessage(0x0201, On_WM_LBUTTONDOWN)
	; 监听鼠标移动消息 实时显示提示
	OnMessage(0x0200, WM_MOUSEMOVE)
	;OnMessage(0x004E, WM_NOTIFY) ; NM_HOVER (list view) notification code https://learn.microsoft.com/en-us/windows/win32/controls/nm-hover-list-view

	;OnMessage(0x0100, WM_KEYDOWN) ; https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
	;OnMessage(0x0104, WM_SYSKEYDOWN)
	; WM_ACTIVATE := 0x0006 窗口激活、失去激活
	; WM_SETFOCUS = 0x0007; 获得焦点后 WM_KILLFOCUS = 0x0008; 失去焦点
	OnMessage(0x06, WM_ACTIVATE) ; 窗口激活/非激活事件

	;WinWaitClose "ahk_id" ParentHwnd ; 随Claunch窗口关闭
	;WinWaitNotActive MyGui ; 自身窗口失去焦点就关闭
	;if GV_CloseOnLoseFocus
		;CloseMyGui()

	;===================================================
	
	WM_ACTIVATE(wParam, lParam, nmsg, CurrentHwnd) {
		;msgbox "----" wParam " / " CurrentHwnd " / " GV_Gui_Hwnd
		if wParam = 0 { ; 当 wParam 为0时表示窗口变为非活动状态
			SetTimer CloseOnLoseFocus, -100 ; 延迟100ms确保操作完成
		}
	}
	
	ToggleTop(*){
		GV_CloseOnLoseFocus := !GV_CloseOnLoseFocus
		WinSetAlwaysOnTop -1, "A"
		btnToggleTop.Text := GV_CloseOnLoseFocus ? "⛔" : "☑"  ; "T" : "⊥" ⌅  －＋
		;CloseOnLoseFocus()
	}
	
	CloseOnLoseFocus(){
		ToolTip ; 清除提示
		if GV_CloseOnLoseFocus
			CloseMyGui()
	}
	
	CloseMyGui(*){
		AddToHistory(ComBox)
		Sleep 1
		OnMessage(0x0200, WM_MOUSEMOVE, 0) ; 取消消息回调
		;OnMessage(0x0201, On_WM_LBUTTONDOWN, 0)
		OnMessage(0x06, WM_ACTIVATE, 0) ; 必须
		;OnMessage(0x004E, WM_NOTIFY, 0)

		Sleep 100 ; 防止AddToHistory()未结束就销毁了窗口，获取控件S值时报错
		MyGui.Destroy() ; 关闭窗口
		GV_Gui_Hwnd := 0
		GV_btnTop_Hwnd := 0
		GV_LV_Hwnd := 0
		GV_CopyTipText := ""
		ToolTip ; 防止有提示未关闭
	}

	WM_KEYDOWN(wParam, lParam, nmsg, CurrentHwnd) { ; 待完善
		static VK_UP := 0x26
		static VK_DOWN := 0x28
		static VK_Enter := 0x0D
		static VK_ESC:=0x1B
		static VK_RETURN := 13
		gc := GuiCtrlFromHwnd(CurrentHwnd)

		if !(wParam = VK_UP || wParam = VK_DOWN || wParam=VK_Enter || wParam=VK_ESC) ; 不响应这四个以外的按键
			return
		if  gc is Gui.Edit 
		{
			; press up & down in Eidt control to select item in listview
			PostMessage nmsg, wParam, lParam, LV
			return true
		}
	}
	
	; 消息处理函数 在窗口背景区域单击拖动 移动窗口
	On_WM_LBUTTONDOWN(*){
	    ;Static init := OnMessage(0x0201, On_WM_LBUTTONDOWN)
	    PostMessage 0xA1, 2
	}

	ShowComboDropDown(comboBoxCtrl) { ; ComboBox控件弹出下拉列表
	    ; CB_SHOWDROPDOWN = 0x014F
	    PostMessage(0x014F, 1, 0, comboBoxCtrl)
	}
	; 添加历史记录到下拉框选项
	FillComBox(ComBox){
		initStatus := true ; 初始化状态标志
		if !FileExist(RunLogIni)
			return
		ComBox.Delete()
		SearchHistory := IniRead(RunLogIni, "SearchHistory", , "") 
		if SearchHistory {
			GV_SearchHistoryArr := StrSplit(SearchHistory, "`n", "`r")
			ComBox.Add(GV_SearchHistoryArr) ; 添加整个数组
		} else
			GV_SearchHistoryArr := []
			
		return GV_SearchHistoryArr.Length ; 返回添加的条目数
	}

	; 保存搜索历史记录到配置ini
	AddToHistory(GuiCtrl, *){
		if initStatus
			return
		editText := Trim(GuiCtrl.Text)
		if editText = ""
			return
		if GV_SearchHistoryArr.Length > 0 && editText = GV_SearchHistoryArr[1] ; 避免重复触发 运行按钮触发一次，窗口关闭时二度触发时报错ComBox控件已销毁
			return
		
		GV_SearchHistoryArr.InsertAt(1, editText)
		GV_SearchHistoryArr := ArrayUnique(GV_SearchHistoryArr)
		if GV_SearchHistoryArr.length > GV_SearchHistoryN
			GV_SearchHistoryArr.Pop()

		IniDelete RunLogIni, "SearchHistory"
		IniWrite ArrayJoin(GV_SearchHistoryArr, "`n"), RunLogIni, "SearchHistory" ; 写入整个章节
		
		if !GV_Gui_Hwnd ; 防止窗口失焦导致关闭，不存在对象而报错
			return		
		ComBox.Delete()
		ComBox.Text := editText
		ComBox.Add(GV_SearchHistoryArr)
	}

	; 拖拉调整窗口大小 列表自动变化
	Gui_Size(GuiObj, MinMax, Width, Height){
		LV.Move(,, Width - 2*MyGui.MarginX, Height - editHgt - 3*MyGui.MarginY- sbarHgt)
		LV.ModifyCol(7, "AutoHdr")
		;LV.Redraw()
	}

	; 默认按钮的动作 响应回车键
	DefaultAction(*){
		if GV_F5 { ; F5强制调用ev搜索全盘
			initStatus := false
			GV_F5 := 0
			SearchTerm := Trim(ComBox.Text)
			if SearchTerm != ""
				EverythingSearch(SearchTerm, false) ; 第二个参数 是否wfn:匹配全名
			return
		}
		
		if initStatus { ; 首次回车时 搜索按钮
			Search(ComBox)
			return
		}
			
		if !LV.Visible { ; 如果CLaunch中没有找到按钮 (此时LV不可见)  调用ev搜索
			SearchTerm := Trim(ComBox.Text) ; EditCtrl.Value
			if SearchTerm != ""
				EverythingSearch(SearchTerm, false) ; 第二个参数 是否wfn:匹配全名
			return
		}
		
		if GV_SelectIndex >= 0 { ; 是Alt+0~9 激发按钮的
			if GV_SelectIndex = 0
				GV_SelectIndex := LV.GetCount() ; Alt+0 打开最后一项
			LVRun(LV, GV_SelectIndex)
			GV_SelectIndex := -1
		} else if GV_GoWebsite { ; 按 ` 触发的 
			GV_GoWebsite := 0
			Item := LV.GetNext()
			if Item {
				if RegExMatch(LV.GetText(Item, 7), "i)(<(ftp|https?):\/\/.+?>)", &argURL) ; 如果提示文本包含<网址>
				Run Trim(Trim(argURL[1], "<>")) ; 使用默认浏览器打开网址
			}
		} else { ; 按回车键触发的
			if LV.GetCount() = 1 {
				LVRun(LV, 1) ; 只有一行时直接启动它
			} else if LV.Focused {
				Item := LV.GetNext() || 1 ; 执行光标下高亮的行, 无(光标下是超出的空白行)则取首行
				LVRun(LV, Item)
			} else 
				LV.Focus()
		}
	}

	; 打开按钮对应的文件路径
	LVGoPath(GuiCtrl, Item, IsRightClick, X, Y){ ; Item是ListViewk控件中被点击的行号或id, IsRightClick右键触发为真，Menu键或Shift+F10触发则为佳
		if IsRightClick {
			ToolTip ; 关闭存在的提示
			GV_CopyTipText := ""
			exePath := GuiCtrl.GetText(Item, 3) ; 程序路径
			if RegExMatch(exePath, "i)((ftp|https?):\/\/.+)", &argURL) { ; 如果包含网址
				Run argURL[1] ; 这会使用默认浏览器打开网址 (右键点击行触发)
			} else {
				exePath := EnvDeref(exePath)
				ShowFileInFoler(exePath)
			}
		}
	}

	; 运行按钮
	LVRun(GuiCtrl, eInfo, *){ ; 第2个参数eInfo 是点击的行号  https://wyagd001.github.io/v2/docs/lib/GuiOnEvent.htm#Click
		ToolTip ; 关闭可能存在的提示
		GV_CopyTipText := ""
		if !GV_Gui_Hwnd ; 防止窗口失焦导致关闭，不存在对象而报错
			return
		;GuiCtrl.Focus()

		rn := GuiCtrl.GetNext() ; C 下一个选中的行，F 焦点行
		;msgbox rn " / " eInfo
		if rn = 0 || eInfo = 0
			return
		if eInfo > GuiCtrl.GetCount() { ; 超过总行数
			ToolTipT("行号超出范围", , 80, 40 )
			return
		}
		btnIdx := GuiCtrl.GetText(eInfo, 1) || -1 ; 在原数组Buttons中的索引
		;if type(btnIdx) = "String" ; 空行的值是列标题
		;	return
		needSpace := " "
		arg := ""
		wkDir := ""
		runAsAdmin := ""

		if btnIdx > 0 { ; 在原Buttons数组中的按钮
			exeFile := Buttons[btnIdx].File
			RunLogKey := Buttons[btnIdx].RunLogKey
			arg := Trim(Buttons[btnIdx].Parameter)
			wkDir := Buttons[btnIdx].Directory
			runAsAdmin := Buttons[btnIdx].asAdmin ? "*RunAs " : ""
		} else { ; Everything搜到后添加的按钮
			exeFile := GuiCtrl.GetText(eInfo, 3)
			wkDir := GuiCtrl.GetText(eInfo, 7)
			RunLogKey := exeFile
		}

		;if RegExMatch(exeFile, "i)^(ftp|https?):\/\/") ; 如果是未指定浏览器的网址
		if RegExMatch(exeFile, "i)^[\w-]{2,}:") { ; 如果是未指定浏览器的网址 或 shell:命令 或 ms-windows-store: 或 windowsdefender: 或 此电脑shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}
			needSpace := ""
			
		} else { ; 常规的exe文件
			exeFile := EnvDeref(exeFile) ; 解析环境变量
			if !FileExist(exeFile) {
				;ToolTipT("路径无效：" exeFile "`n改用Everything搜索文件名", 80, 40)
				SplitPath exeFile, &exeName
				EverythingSearch(exeName, true) ; 第二个参数 是否wfn:匹配全名
				return
			}
			exeFile := GetTargetOfLink(exeFile) ; 如果是符号链接 或 junction, 解析到其目标
			if InStr(exeFile, '"') = 0
				exeFile := '"' exeFile '"'
		}

		if arg = "" {
			needSpace := ""
		} else if InStr(arg, "<clipboard>")
			arg := ReplaceWithClip(arg)

		if wkDir = "" || !FileExist(wkDir)
			wkDir := CLfolder
		;msgbox exeFile needSpace arg " / " wkDir

		try {
			Run(runasAdmin exeFile needSpace arg, wkDir) ; 注意：若wkDir路径无效，则报错信息与无wkDir参数时并不一样
			
			if RunLogMap.Has(RunLogKey) {
				RunLogMap[RunLogKey] += 1
			} else {
				RunLogMap[RunLogKey] := 1
			}
			LV.Modify(eInfo, "Col4", RunLogMap[RunLogKey])
			IniWrite RunLogMap[RunLogKey], RunLogIni, "RunLog", RunLogKey
		} catch ERROR as err {
			MsgBox err.Message "`n`n行号: " err.Line "`n执行: " err.What  "`n具体: " err.Extra "`n跟踪: `n" err.Stack
		}
		
		; 让这种Claunch按钮 也能执行============
		; Name=lux
		; File=%ComSpec%
		; Parameter=/K ( "lux.exe" <clipboard>  )
		; Directory=..\DownCloud\lux

		; 另外注意：Run 无法启动符号链接的exe (cmd中也一样)
		; 如：绿色版QQ  ....\Tencent\QQ\Bin\QQScLauncher.exe

	}
	
	Search(GuiCtrl, *){
		initStatus := false
		if !GV_Gui_Hwnd ; 调试出现msgbox弹窗时，窗口失焦导致关闭，此时若不存在窗口对象，则终止
			return

		;SearchTerm := RegExReplace(Trim(GuiCtrl.Value), "\s+", A_Space) ; 多个连续空格替换为一个空格
		SearchTerm := RegExReplace(Trim(GuiCtrl.Text), "\s+", A_Space) ; 多个连续空格替换为一个空格
		;matchArr := StrSplit(SearchTerm, [A_Space, A_Tab])
		LV.Delete()
		If (SearchTerm = "") {
			AdjustWindowHeight()
			return
		}
		;AddToHistory(ComBox) ; 放在这里不好，因为change事件会实时触发太多次
		;LV.Redraw() ; 重绘可避免重叠，但可能导致闪烁
		LV.Opt("-Redraw") ; https://wyagd001.github.io/v2/docs/lib/GuiControl.htm#Redraw
		rowN := 0
		For butn In Buttons
		{
			; If (InStr(CS.1, SearchTerm) || InStr(CS.2, SearchTerm) || InStr(CS.3, SearchTerm))
			/*
			if ( 拼音_匹配(SearchTerm, butn.Name) || 
					拼音_匹配(SearchTerm, butn.Tip) || 
					拼音_匹配(SearchTerm, butn.File) || 
					拼音_匹配(SearchTerm, butn.Parameter) || 
					拼音_匹配(SearchTerm, butn.exePath) || 
					拼音_匹配(SearchTerm, butn.Directory) ) {
				*/
			; 实现以空格分割的多关键字搜索 空格=与
			;idx := A_Index
			matchFlag := true
			Loop Parse, SearchTerm, A_Space A_Tab {
				;if idx < 3 ; 方便调试
					;msgbox A_LoopField " / " butn.searchField
				if !拼音_匹配(A_LoopField, butn.searchField) {
					matchFlag := false
					Break
				}
			}
			if matchFlag {
				rowN++
				;LV.Add("", butn.Name, butn.exePath, butn.Tip, butn.File, butn.Parameter, butn.Directory)
				LogN := 0
				if RunLogMap.Has(butn.RunLogKey)
					LogN := RunLogMap[butn.RunLogKey]
				LV.Add("", A_Index, butn.Position, butn.exePath, LogN, rowN, butn.Name, butn.Tip )
			}
			;else if (SearchTerm = "") 
				;LV.Add("", A_Index, butn.Position, butn.exePath, LogN, rowN, butn.Name, butn.Tip ) ; 未输入内容时加载所有按钮
		}
		AdjustWindowHeight()

		;LV.ModifyCol()  ; 根据内容自动调整每列的大小
		;LV.Redraw()
		;WinRedraw MyGui
	}

	EverythingSearch(str, wfn:=true){
		if !ProcessExist("Everything.exe") && !ProcessExist("Everything64.exe"){
	        MsgBox "要使用Everything搜索程序，请先启动它！", , "Owner" GV_Gui_Hwnd
	        return
	    }
		try evObj := Everything()
		catch Error as err {
			MsgBox err.Message "`n行号 : " err.Line "`n`n溯源 : `n" err.Stack, , "T5"
			return
		}
		;OnMessage(0x0200, WM_MOUSEMOVE, 0)
		ToolTip
		;EvIsAdminStatus:=evObj.GetIsAdmin() ? "管理员权限" : "非管理员"
		if wfn
			str := 'file: !?:\$RECYCLE*\ wfn:"' str '"' ; 搜索可执行文件 排除回收站
		else 
			str := "file: !?:\$RECYCLE*\ ext:exe;bat;com;cmd;lnk;msc;cpl;vbs;msi;msp;ps1;reg;scr " str
		
		evObj.SetSearch(str)
		evObj.SetMax(50) ; 限制返回的最大结果数
		evObj.SetSort(14) ; 14=修改时间_降序
		;evObj.SetMatchWholeWord() ; 文件名匹配完整单词 是ww: 而非wfn:
		evObj.SetRequestFlags(4) ; 获取完整路径和文件名 =默认值3
		evObj.Query()
		rowCount := evObj.GetNumResults() ; 可见结果的数量
		TotalItems := evObj.GetTotResults() ; 所有结果的数量
		;msgbox rowCount " / " TotalItems
		if (rowCount > 0) {
			LV.Delete()
			;LV.Redraw() ; 重绘可避免重叠，但可能导致闪烁
			LV.Opt("-Redraw") 
			/*
			fileFullPath := evObj.GetResultFullPathName(0) ; 搜索结果中第一项的完整路径
			ToolTipT("EV搜到：" fileFullPath)
			if fileFullPath != "" {
				;ShowFileInFoler(fileFullPath) ; 附加前缀"\t" 直接打开文件夹，否则打开其父文件夹
				Run fileFullPath ; 直接启动第一项结果
			}*/
			Loop rowCount {
				filePath := evObj.GetResultFullPathName(A_Index-1)
				SplitPath filePath, &fileName, &OutDir ; workdir 
				LogN := 0
				if RunLogMap.Has(filePath)
					LogN := RunLogMap[filePath]
				LV.Add("", 0, "Everything搜到", filePath, LogN, A_Index, fileName, OutDir )
			}
			AdjustWindowHeight("在Everything搜索结果中")
			;LV.Redraw()
		} else {
			;MsgBox "Everything 未搜到此程序.                     ", , "T2 Owner" GV_Gui_Hwnd ; 弹窗会导致搜索窗口失去焦点而关闭

			; 改用ToolTip提示
			ComBox.GetPos(&cX, &cY)
			ToolTipOptions.SetColors("C12810", "White") ; 设置提示颜色为 红色白字
			ToolTipT("Everything 未搜到此程序.", 3000, cX+20, cY+40)
			ToolTipOptions.SetColors("F2F2D7", "000000") ; 提示条恢复默认颜色
		}
		evObj := ""
	}

	; Trae AI 问得
	AdjustWindowHeight(BarText := "在CLaunch中") {
		;static ROW_HEIGHT := 20  ; 每行高度（根据实际字体调整）
		;static MIN_ROWS := 1     ; 最小显示行数
		static MAX_ROWS := 20     ; 最大显示行数
		;static MAX_HEIGHT := 600 ; 窗口最大高度
		static ScrollBarH := SysGet(3) ; 系统水平滚动条的高度
		; https://www.autohotkey.com/boards/viewtopic.php?t=126573 检测是否存在滚动条
		;static WS_HSCROLL := 0x00100000 ; horizontal scroll bar
   		;static WS_VSCROLL := 0x00200000 ; vertical scroll bar
		;static SM_CYHSCROLL := 3, SM_CXVSCROLL := 2 ; 水平滚动条的高度，垂直滚动条的宽度 https://wyagd001.github.io/v2/docs/lib/SysGet.htm
			
		; 计算需要显示的行数
		rowCount := LV.GetCount()
		StaBar.SetText("   " rowCount " / 共 " TotalItems " 项  " BarText)
		if rowCount = 0
			LV.Visible := false
		else {
			;msgbox rowCount
			visibleRows := rowCount > MAX_ROWS ? MAX_ROWS : rowCount
			; 计算新高度
			;newLVHeight := visibleRows * RowHeight + LV_HeaderH	
			newLVHeight := visibleRows * RowHeight + LV_HeaderH + ScrollBarH ; 如果超过MAX_ROWS，底部滚到条额外占一行高度

			LV.Move(,,, newLVHeight)
			LV.ModifyCol(4, "SortDesc") ; 按启动次数降序
			LV.ModifyCol(5, "Auto Right")
			
			Loop LV.GetCount() {
				LV.Modify(A_Index, "col5", A_Index) ; 排序后重新赋值行号
			}
			
			LV.Visible := true
			;if !(ControlGetStyle(LV.Hwnd) & WS_HSCROLL) ; 如果不存在水平滚动条，不增加额外高度 (不可见时无法判断 没什么用)
				;ScrollBarH := 0
			;LV.Move(,,, newLVHeight + ScrollBarH)
			LV.Modify(1, "Focus Select Vis") ;选择第一行
	    }
	    MyGui.Show("AutoSize")
	    LV.Opt("+Redraw")
	}

	LVTip(GuiCtrl, Item){
		TT := LV.GetText(Item, 3) ; 程序路径
		TipText := ""
		if LV.GetText(Item, 1) > 0
			TipText := LV.GetText(Item, 7) ; 提示文本
		if Trim(TipText) {
			GV_CopyTipText := TipText
			TT := Trim(TT "`n" TipText)
		}
		TT2 := LV.GetText(Item, 4) ; 启动次数
		if TT
			ToolTip TT "`n按钮位置: " LV.GetText(Item, 2) "`n启动次数: " TT2
		else {
			ToolTip
			GV_CopyTipText := ""
		}
	}

	; 鼠标经过时显示提示信息
	; https://learn.microsoft.com/zh-cn/windows/win32/learnwin32/mouse-movement  鼠标移动消息
	; LVM_HITTEST   -> docs.microsoft.com/en-us/windows/desktop/Controls/lvm-hittest
	; LVHITTESTINFO -> docs.microsoft.com/en-us/windows/desktop/api/Commctrl/ns-commctrl-taglvhittestinfo
	; 谷歌搜索 autohotkey listview mouse over tooltip
	; https://www.autohotkey.com/boards/viewtopic.php?t=63436
	; http://msdn.microsoft.com/en-us/library/bb774754%28VS.85%29.aspx
	WM_MOUSEMOVE(wParam, lParam, Msg, Hwnd) {
		static mouseX := "", mouseY := "", PrevLine := -1, PrevHwnd := 0
		eventMouse := 1
		TT := ""
		LV_Hwnd := 0
		nowX := lParam & 0xFFFF
		nowY := (lParam >> 16) & 0xFFFF
		if mouseX == nowX && mouseY == nowY ; 未移动鼠标，不重新ToolTip 避免闪烁
			return
		mouseX := nowX, mouseY := nowY ; 保存上次触发时的鼠标位置
		try LV_Hwnd := LV.Hwnd ; 防止窗口关闭导致LV销毁后调用对象报错
		If (Hwnd = LV_Hwnd) {
			LVHTI := Buffer(24, 0)
			; 写入鼠标坐标（v2使用新的写入方法）
			;ToolTip nowX ":" nowY " / " mouseX ":" mouseY ; 相对于控件左上角的坐标
			NumPut("Int", nowX, LVHTI, 0) ; X坐标
			NumPut("Int", nowY, LVHTI, 4) ; Y坐标
			; 执行命中测试 LVM_HITTEST（v2需要显式类型转换）
			Item := DllCall("SendMessage", "Ptr", Hwnd, "UInt", 0x1012, "Ptr", 0, "Ptr", LVHTI.Ptr, "Ptr") ; LVM_HITTEST
			; https://www.autohotkey.com/boards/viewtopic.php?t=77789
			;SendMessage(LVM_SUBITEMHITTEST, 0, &LVHITTESTINFO,, Ahk_ID %MyLVHwnd%)
			; 检查命中结果
			Item += 1
			if Item != PrevLine {
				;LV.Modify(0, "-Select") ; 全不选
				LV.Modify(Item, "Select") ; 选择光标下的行
				PrevLine := Item
			}
			If (Item > 0) && (NumGet(LVHTI, 8, "UInt") & 0x0E) ; LVHT_ONITEM
				LVTip(LV, Item)
		} else if Hwnd = GV_btnTop_Hwnd {
			if (Hwnd != PrevHwnd) {
		        ToolTip ; 关闭之前的工具提示.
		        GV_CopyTipText := ""
		        CurrControl := GuiCtrlFromHwnd(Hwnd)
		        if CurrControl {
		            if !CurrControl.HasProp("ToolTip")
		                return ; 此控件没有工具提示.
		            TT := CurrControl.ToolTip
		            SetTimer () => ToolTipT(TT, 3000), -300
		        }
	        }
		} else {
			ToolTip ; 超出listview空间范围 隐藏提示
			GV_CopyTipText := ""
		}
		
		PrevHwnd := Hwnd
	}

	/*
	; https://www.autohotkey.com/board/topic/97641-how-to-change-the-highlight-color-of-listview-when-hovering/
	; https://www.autohotkey.com/board/topic/64107-hot-track-selection-issue-with-listview/
	; http://msdn.microsoft.com/en-us/library/bb774869(VS.85).aspx
	; https://learn.microsoft.com/zh-cn/windows/win32/controls/list-view-control-reference  LVN_HOTTRACK
	; https://learn.microsoft.com/zh-cn/windows/win32/controls/lvn-hottrack
	WM_NOTIFY(wParam, lParam, Msg, Hwnd){
		;Critical 30 ; Give this function some time to finish before next peek at the message queue in order not to miss subsequent WM_NOTIFY messages sent by the listview
		static PrevLine := -1
		TT := ""
		; https://www.autohotkey.com/boards/viewtopic.php?p=591938#p591938
		; I got the offset using Structor.ahk https://www.autohotkey.com/boards/viewtopic.php?t=31711
		code := NumGet(lParam, 2*A_PtrSize, "Int") ; 此例中code=-121 NMLISTVIEW / NMHDR structure member 'code' equals to -121 (LVN_HOTTRACK)
		ToolTip code " ----------"
		if (code = -121) {
			;ToolTip "-------------"
			;item := NumGet(lParam, (A_PtrSize = 8 ? 24 : 12), "Int")
			Item := NumGet(lParam, 3*A_PtrSize, "Int") + 1
			; Do whatever you need with the information
			if Item != PrevLine {
				LV.Modify(0, "-Select")
				LV.Modify(Item, "Select")
			}
			If Item > 0 { ; LVHT_ONITEM
				TT := LV.GetText(Item, 3)
				TT3 := LV.GetText(Item, 7)
				if Trim(TT3) 
					TT := Trim(TT "`n" TT3)
			}
			;ToolTip TT ; 缺点：当光标移出ListView控件的行列之外时，无法自动消失
			PrevLine := Item
		}
		else if code = -13 {
			;ToolTip "+++++++++++++"
		}
		return 1 ; Return nonzero.
	}
	
	NM_HOVER(GuiControl, lParam){
		code := NumGet(lParam, 2*A_PtrSize, "Int")
		msgbox code
	}
	*/
}

; 公用函数==========================================================

;提示工具条 超时自动关闭  from EzTip
ToolTipT(str, timeout:=2000, posX:="", posY:=""){ ; 
	timeout := (timeout>0) ? timeout : 2000
	CoordMode "ToolTip", "Window"
	if posX = "" || posY = ""
		ToolTip str
	else 
		ToolTip str, posX, posY
	;Sleep timeout ; 不好 会阻塞线程
	;ToolTip
	SetTimer () => ToolTip(), -timeout
}

; 获取焦点控件的类型
FocusClassNN(){
	try return ControlGetClassNN(ControlGetFocus("A"))
	catch 
		return ""
}

;判断是不是相对路径  (注意环境变量%xxx%的情况，在文件名中%是合法字符，这里不考虑含%却不是环境变量的文件名)
; 以 ..\ 或 .\ 开头，不以X:\开头，不以%xxx%环境变量开头，不含冒号的， 视为相对路径 (如CLsearch.exe)
; 可以简化为：不含冒号: 且 不以%xxx%变量开头的 都视为相对路径，其他如< X:\ %windir% http:\\ shell:  UNC路径\\server\share >都视为绝对路径
IsRelativePath(path){
	if !InStr(path, ":") && !RegExMatch(path, "^(\\|%[^%]+%)")
		return true
	return false
}

; 从相对路径获取其绝对路径
GetFullPathName(path) {
    cc := DllCall("GetFullPathNameW", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint") ; "GetFullPathName"
    buf := Buffer(cc*2) ; buf := BufferAlloc(cc*2)
    DllCall("GetFullPathNameW", "str", path, "uint", cc, "ptr", buf, "ptr", 0, "uint")  ; "GetFullPathName" (最后一个参数"uint"可去掉，因为无需返回值)
    return StrGet(buf)
}

;调用资源管理器替代程序打开文件路径并选中 (比如DOpus替代资管 会定位到DO中 而不是直接调用explorer)
ShowFileInFoler(filepath) { ; OpenAndSelect(filepath)
	; Run Format('explorer.exe /select,"{1}"', filepath)
	filepath := Trim(filepath)
	if RegExMatch(filepath, "i)^\w{2,}:") { ; shell:Startup命令 或 网址https:// 之类
		Run filepath
		return
	}
		
	if !FileExist(filepath) {
		ToolTipT "路径无效：" filepath
		return
	}
	DllCall("shell32\SHParseDisplayName", "Str", filepath, "Ptr", 0, "Ptr*", &pidl := 0, "UInt", 0, "Ptr", 0, "HRESULT")
	DllCall("shell32\SHOpenFolderAndSelectItems", "Ptr", pidl, "UInt", 0, "Ptr", 0, "UInt", 0, "HRESULT")
	DllCall("ole32\CoTaskMemFree", "Ptr", pidl)
}

; 关于AHK Run 的问题: (NirCmd.exe也是一样)
; Run 在执行符号链接(.symlink)的exe时，不会解析获取其目标来启动
; 而在文件管理器(DOpus,TC,XY,资管等)中双击符号链接exe，会自动解析其目标来启动
; 用 SystemInformer 来看进程的 Command Line，能看的一清二楚
; 因此Run可能无法启动符号链接exe程序，因为exe文件夹中缺少目标路径里的依赖文件
; 并且出现这种启动失败的情况，有可能无任何弹窗报错提示。测试可知，AHK的Run 相当于下面的shell.exec
; 例如: 把 filezilla.exe 创建符号链接，就是这样
; 而 shell.Run 相当于文件管理器中双击exe文件，执行符号链接filezilla.exe会出现弹窗报错提示
; https://wyagd001.github.io/v2/docs/lib/Run.htm#ExecScript
ShellRun(cmdstr){
    shell := ComObject("WScript.Shell")
    exec := shell.Run(cmdstr)
    ;exec := shell.exec(cmdstr) ; 可获取输出 exec.StdOut.ReadAll()
}

;获取光标下控件的类型
MouseOverClass(){
    try {
    	MouseGetPos , , , &ctrlClass ; MouseGetPos 对Win+V弹出的剪贴板历史窗口 无效 会报错
    	return ctrlClass
    } catch
    	return ""
}

; 获取软链接/符号链接的目标路径
; https://www.autohotkey.com/boards/viewtopic.php?style=19&t=125022
; https://www.autohotkey.com/boards/viewtopic.php?t=37965
; https://www.autohotkey.com/boards/viewtopic.php?t=78509
GetTargetOfLink(path){
	target := ""
	path := Trim(path, '"') ; FileGetAttrib()的入参不能有引号，必须去掉
	if InStr(FileGetAttrib(path), "L") { ; 如果是符号链接 或 junction
		hFile := DllCall("CreateFile", "Str", path, "UInt", 0, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 0x02000000, "Ptr", 0, "Ptr")
		if (hFile = -1)
			return path
		; 准备缓冲区
		bufSize := 260 * 2  ; UNICODE路径最大长度
		outStr := Buffer(bufSize, 0)
    	; 调用GetFinalPathNameByHandle
		ret := DllCall("GetFinalPathNameByHandle", "Ptr", hFile, "Ptr", outStr, "UInt", bufSize, "UInt", 0x0, "UInt") ; 0x0 = VOLUME_NAME_DOS
		DllCall("CloseHandle", "Ptr", hFile) ; 关闭句柄

		; 处理返回结果
		if (ret > 0 && ret <= bufSize) {
			target := StrGet(outStr)
			; 移除前缀"\\?\" (如果存在)
			if (SubStr(target, 1, 4) = '\\?\')
				target := SubStr(target, 5)
   		}
	}
	return target="" ? path : target
}
		
; https://www.autohotkey.com/boards/viewtopic.php?style=7&t=124114
; Resolve 解析环境变量路径
;Run EnvDeref("%USERPROFILE%\Desktop\app.lnk")
EnvDeref(Str) {
	spo := 1 ; start position
	out := ""
	while (fpo:=RegexMatch(Str, "(%(.*?)%)|``(.)", &m, spo))
	{
		out .= SubStr(Str, spo, fpo-spo)
		spo := fpo + StrLen(m[0])
		if (m[1]) {
			out .= (env := EnvGet(m[2])) ? env : m[1]
		} else {
			out .= m[3]
		}
	}
	return out SubStr(Str, spo)
}

ReplaceWithClip(Str) {
	clipbd := "<clipboard>"
	spo := 1 ; start position
	out := ""
	while (fpo:=RegexMatch(Str, "i)(<clipboard>)", &m, spo))
	{
		out .= SubStr(Str, spo, fpo-spo)
		spo := fpo + StrLen(m[0])
		if (m[1]) {
			out .= A_Clipboard
		}
	}
	return out SubStr(Str, spo)
}

;数组去除重复元素 使元素唯一 保持顺序
; https://www.autohotkey.com/boards/viewtopic.php?t=39697
ArrayUnique(arr){
	/* https://stackoverflow.com/questions/46432447/how-do-i-remove-duplicates-from-an-autohotkey-array
	for i, value in arr
		for j, inner_value in arr
			if (A_Index > i && value = inner_value)
				arr.Remove(A_Index)
	*/

	; Hash O(n) - Linear
    hash := Map(), newArr := []
	for e, v in arr {
		if (!hash.Has(v))
			hash[v] := 1, newArr.Push(v)
	}
	return newArr
}

;AHK的数组对象没有join方法，用此可将数组中非空元素连接为字符串 (delimiter是连接字符，limit限制连接元素的数量，0为不限制)
; ArrayJoin(arr, "`n")
ArrayJoin(array, delimiter := "", limit := 0) {
	result := "", first := true, count := 0
	for item in array {	
		if (limit > 0 && count >= limit)
			Break
		item := Trim(item, ' "`t`r`n')
		if item {
			if !first
				result .= delimiter
        	;result .= item
        	result .= item
			first := false
			count++
		}
	}
	return result
}

;https://www.autohotkey.com/boards/viewtopic.php?t=116025  获取补色
;Color := 0xFF0000
;MsgBox Format('0x{:06X}', ComplementaryColor(Color))
ComplementaryColor(Color) {
   R1 := (Color & 0xFF0000) >> 16
   G1 := (Color & 0x00FF00) >>  8
   B1 := (Color & 0x0000FF)
   R2 := 0xFF - R1
   G2 := 0xFF - G1
   B2 := 0xFF - B1
   R2 := R2 - R1 < 10 ? 0 : R2
   G2 := G2 - G1 < 10 ? 0 : G2
   B2 := B2 - B1 < 10 ? 0 : B2
   return (R2 << 16) | (G2 << 8) | B2
}

;https://www.autohotkey.com/boards/viewtopic.php?f=83&t=125259&hilit=lv+color
;https://www.autohotkey.com/boards/viewtopic.php?f=83&t=93922
;更改ListView控件的Grid表格线的颜色  https://www.autohotkey.com/boards/viewtopic.php?style=8&t=90151
LV_GridColor(LV, color?) {
    static LVSubclassCB := CallbackCreate(LVSubclassProc, 6)
    static Pens := Map()

    hLV := LV.hwnd

    if !IsSet(color) {
        if Pens.Has(hLV) {
            DllCall("DeleteObject", "ptr", Pens[hLV])
            DllCall("RemoveWindowSubclass", "ptr", hLV, "ptr", LVSubclassCB, "ptr", ObjPtr(LV))
        }
        return
    }

    ; RGB to BGR
    color := color >> 16 | (color & 0xFF00) | (color & 0xFF) << 16

    if Pens.Has(hLV) {
        DllCall("DeleteObject", "ptr", Pens[hLV])
        Pens[hLV] := DllCall("CreatePen", "uint", 0, "uint", 1, "uint", color)
        return
    }

    Pens[hLV] := DllCall("CreatePen", "uint", 0, "uint", 1, "uint", color)
    DllCall("SetWindowSubclass", "ptr", hLV, "ptr", LVSubclassCB, "ptr", ObjPtr(LV), "ptr", 0)

    static LVSubclassProc(H, M, W, L, I, R) {
        Critical
        static WM_NOTIFY := 0x004E
        static WM_PAINT := 0x000F
        static WM_DESTROY := 0x0002
        static LVM_GETHEADER := 0x101F
        static LVM_GETEXTENDEDLISTVIEWSTYLE := 0x1037
        static LVS_EX_GRIDLINES := 0x1
        static HDM_GETITEMCOUNT := 0x1200
        static LVM_GETCOUNTPERPAGE := 0x1028
        static LVM_GETCOLUMNWIDTH := 0x101D
        static LVM_GETITEMRECT := 0x100E

        switch M {
        case WM_PAINT:
            ; based on: https://web.archive.org/web/20081204015020/http://www.codeguru.com/cpp/controls/listview/gridlines/article.php/c963/#more
            ; If Grid is enabled, draw custom grid.
            if SendMessage(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0, H) & LVS_EX_GRIDLINES
            {
                ; First let the control do its default drawing.
                DllCall("DefSubclassProc", "ptr", H, "uint", M, "ptr", W, "ptr", L, "ptr")
                pen := Pens[H]
                hdc := DllCall("GetDC", "ptr", H)
                HHEADER := SendMessage(LVM_GETHEADER,,, H)
                col_count := SendMessage(HDM_GETITEMCOUNT,,, HHEADER)
                ; The bottom of the header corresponds to the top of the line.
                WinGetClientPos(,,, &Top, HHEADER)
                WinGetClientPos(,, &Width, &Height, H)
                oldPen := DllCall("SelectObject", "ptr", hdc, "ptr", pen)
                ; The border of the width is offset by the horz scroll
                borderx := 0 - DllCall("GetScrollPos", "ptr", H, "uint", 0)
                ; Draw the vertical gridlines.
                loop col_count
                {
                    col_width := SendMessage(LVM_GETCOLUMNWIDTH, A_Index - 1, 0, H)
                    borderx += col_width
                    ; if next border is outside client area, break.
                    if borderx >= Width
                        break
                    DllCall("MoveToEx", "ptr", hdc, "int", borderx, "int", top, "ptr", 0)
                    DllCall("LineTo", "ptr", hdc, "int", borderx, "int", Height)
                }
                rc := Buffer(16, 0)
                SendMessage(LVM_GETITEMRECT, 0, rc, H)
                RowHeight := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
                count_per_page := SendMessage(LVM_GETCOUNTPERPAGE, 0, 0, H)
                ; Draw the horizontal gridlines.
                loop count_per_page
                {
                    DllCall("MoveToEx", "ptr", hdc, "int", 0, "int", top + RowHeight*A_Index-1, "ptr", 0)
                    DllCall("LineTo", "ptr", hdc, "int", Width, "int", top + RowHeight*A_Index-1)
                }
                DllCall("SelectObject", "ptr", hdc, "ptr", oldPen)
                DllCall("ReleaseDC", "ptr", H, "ptr", hdc)
                return 0
            }

        case WM_DESTROY:
                if IsSet(Pens)
                    DllCall("DeleteObject", "ptr", Pens.Delete(H))
                DllCall("RemoveWindowSubclass", "ptr", H, "ptr", LVSubclassCB, "ptr", ObjPtr(GuiCtrlFromHwnd(H)))
        }

        return DllCall("DefSubclassProc", "ptr", H, "uint", M, "ptr", W, "ptr", L, "ptr")
    }
}

;=================================================

/*
; 自定义函数获取精确的ini值
GetIniValue(file, sectionLine, key)
{
    ; 提取原始section名称
    RegExMatch(sectionLine, "^\[(.*)\]$", match)
    section := match[1]
    
    ; 从该section行开始向下搜索
    found := false
    value := ""
    Loop Read, file
    {
        if (A_LoopReadLine = sectionLine)
            found := true
        else if (found && RegExMatch(A_LoopReadLine, "^\["))
            break
        else if (found && RegExMatch(A_LoopReadLine, "^" key "=(.*)$", valMatch))
            return valMatch[1]
    }
    return ""
}
*/
