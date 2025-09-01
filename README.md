# Clsearch
为搜索CLaunch中的按钮而生的AHK2脚本，代替它的Ctrl+F查找，支持拼音简拼、全拼搜索  
An alternative tool for the Ctrl+F search function in CLaunch.

## CLaunch 优化配置：
1. 在 CLaunch 选项/其他：勾选【在相对路径中注册项目】
2. 将 CLsearch 文件夹放入 CLaunch.exe 所在文件夹中，最终路径是：CLaunch\CLsearch\CLsearch.exe  
	将 CLsearch.exe 拖入 CLaunch 页面中成为按钮  
	在 CLaunch 选项/事件: <CLaunch 启动时> 点击【注册】  
	添加 CLsearch 所在页面，然后在对应项目列双击选择 CLsearch  
	这就是让 CLaunch 启动后自动带起 CLsearch。

## 使用说明：
全局热键 Win+C 打开搜索窗口，窗口未置顶时失去焦点自动关闭  
在Claunch窗口激活时，按快捷键 Ctrl+F 弹出搜索窗口，可输入文本进行实时搜索。在搜索窗口按Ctrl+F则关闭。  
如果在Claunch中未搜到按钮，按 回车键/Tab键 可用Everything进行搜索，结果也显示在列表控件中。  
搜索窗口失去焦点后会自动关闭。Ctrl+T 可置顶保持不关闭，与点击右上角⛔按钮等同。  
搜索历史保存在 RunLog.ini，可手动编辑、删除。  
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
 
