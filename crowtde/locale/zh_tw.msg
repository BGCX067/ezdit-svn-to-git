namespace eval ::crowDebugger {
	# New
	::msgcat::mcset zh_tw  "...abort" "...停止"
	# New
	::msgcat::mcset zh_tw  "...ok" "...ok"
	# New
	::msgcat::mcset zh_tw  "Debug script is not specified or not exists.!" "要除錯的檔案還沒指定或不存在.!"
	# New
	::msgcat::mcset zh_tw  "Debugger already running!" "除錯器已經起動!"
	# New
	::msgcat::mcset zh_tw  "Debugger has not started!" "除錯器沒有起動!"
	# New
	::msgcat::mcset zh_tw  "Error" "錯誤"
	# New
	::msgcat::mcset zh_tw  "Interpreter is not specified or not exists!" "直譯器還沒指定或不存在!"
	# New
	::msgcat::mcset zh_tw  "Loading '%s' ..." "載入 '%s' ..."
	# New
	::msgcat::mcset zh_tw  "Start Debugger...ok" "起動除錯器...ok"
	# New
	::msgcat::mcset zh_tw  "Stop Debugger....ok" "停止除錯器....ok"
	# New
	::msgcat::mcset zh_tw  "error" "錯誤"
}

namespace eval ::crowEditor {
	::msgcat::mcset zh_tw  "'%s' has been delete from the file system. Save it?" "'%s' 已經從檔案系統刪除,您要儲存嗎?"
	::msgcat::mcset zh_tw  "'%s' has been deleted from the file system. Save ?" "'%s' 已經從檔案系統刪除,您要儲存嗎?"
	::msgcat::mcset zh_tw  "'%s' has been modified. Reload file ?" "'%s' 內容已經被改變,您要重新載入嗎?"
	::msgcat::mcset zh_tw  "'%s' has been modified. Save changes ?" "'%s' 內容已經被改變,您要儲存嗎?"
	::msgcat::mcset zh_tw  "Add Block Comment"  "插入註解"
	::msgcat::mcset zh_tw  "Backward"  "往後搜尋"
	::msgcat::mcset zh_tw  "Case Sensitive"  "符合大小寫"
	::msgcat::mcset zh_tw  "Colors"  "顏色設定"
	::msgcat::mcset zh_tw  "Comment:"  "注解:"
	::msgcat::mcset zh_tw  "Copy"  "複製"
	::msgcat::mcset zh_tw  "Cut"  "剪下"
	::msgcat::mcset zh_tw  "Cut Line"  "剪下一行"
	::msgcat::mcset zh_tw  "Cut word"  "剪下單字"
	::msgcat::mcset zh_tw  "Default disabled"  "預設禁能"
	::msgcat::mcset zh_tw  "Default enabled"  "預設致能"
	::msgcat::mcset zh_tw  "Delete"  "刪除"
	::msgcat::mcset zh_tw  "Editor Settings" "編輯器設定"
	::msgcat::mcset zh_tw  "Exit"  "離開"
	::msgcat::mcset zh_tw  "Find"  "搜尋"
	::msgcat::mcset zh_tw  "Find And Replace"  "搜尋與取代"
	::msgcat::mcset zh_tw  "Find Next"  "搜尋下一個"
	::msgcat::mcset zh_tw  "Find/Replace..."  "搜尋/取代..."
	::msgcat::mcset zh_tw  "Indent Selection"  "向右縮排"
	::msgcat::mcset zh_tw  "Information"  "信息"
	::msgcat::mcset zh_tw  "Information!" "訊息!"
	::msgcat::mcset zh_tw  "Insert Macro"  "插入巨集"
	::msgcat::mcset zh_tw  "Items"  "項目"
	::msgcat::mcset zh_tw  "Jump To"  "跳躍到"
	::msgcat::mcset zh_tw  "Jump To..."  "跳躍到..."
	::msgcat::mcset zh_tw  "Numerical:"  "數值:"
	::msgcat::mcset zh_tw  "Paste"  "貼上"
	::msgcat::mcset zh_tw  "Redo"  "下一步"
	::msgcat::mcset zh_tw  "Regular expression"  "正規表示式"
	::msgcat::mcset zh_tw  "Remove Block Comment"  "移除註解"
	::msgcat::mcset zh_tw  "Repalce All"  "全部取代"
	::msgcat::mcset zh_tw  "Replace"  "取代"
	::msgcat::mcset zh_tw  "Reset"  "回復預設值"
	::msgcat::mcset zh_tw  "Save"  "儲存"
	::msgcat::mcset zh_tw  "Save File"  "儲存檔案"
	::msgcat::mcset zh_tw  "Save Macro"  "儲存巨集"
	::msgcat::mcset zh_tw  "Save file!"  "儲存檔案!"
	::msgcat::mcset zh_tw  "Save success"  "儲存成功"
	::msgcat::mcset zh_tw  "Select All"  "全選"
	::msgcat::mcset zh_tw  "Select Line"  "選取一行"
	::msgcat::mcset zh_tw  "Select word"  "選取單字"
	::msgcat::mcset zh_tw  "Set Breakpoint" "設定中斷點"
	::msgcat::mcset zh_tw  "String Not Found"  "沒有符合的內容"
	::msgcat::mcset zh_tw  "String:"  "字串:"
	::msgcat::mcset zh_tw  "Syntax Highlight"  "語法標示"
	::msgcat::mcset zh_tw  "Tab width" "Tab寬度"
	::msgcat::mcset zh_tw  "Tcl Argument:" "Tcl參數"
	::msgcat::mcset zh_tw  "Tcl Command:" "Tcl命令:"
	::msgcat::mcset zh_tw  "Tk Argument:" "Tk參數:"
	::msgcat::mcset zh_tw  "Tk Command:" "Tk命令:"
	::msgcat::mcset zh_tw  "Undo"  "上一步"
	::msgcat::mcset zh_tw  "Unindent Selection"  "向左縮排"
	::msgcat::mcset zh_tw  "Unset Breakpoint" "移除中斷點"
	::msgcat::mcset zh_tw  "Variable:"  "變數:"
	::msgcat::mcset zh_tw  "Warring!"  "警告!"
}

namespace eval ::crowExec {
	::msgcat::mcset zh_tw  "%s...Exit" "%s...離開"
	::msgcat::mcset zh_tw  "Error" "錯誤"
	::msgcat::mcset zh_tw  "Interpreter '%s' not exists" "直譯器 '%s' 不存在"
	::msgcat::mcset zh_tw  "Permission denied" "權限不足"
	::msgcat::mcset zh_tw  "Run %s..." "執行 %s..."
	::msgcat::mcset zh_tw  "You may not permission to execuate this file! Execuate force?" "您可能沒有權力執行這個檔案，確定要執行嗎?"
}

namespace eval ::crowFileProperties {
	::msgcat::mcset zh_tw  "Accept" "接受"
	::msgcat::mcset zh_tw  "Accessed:" "最後存取時間:"
	::msgcat::mcset zh_tw  "Cancel" "取消"
	::msgcat::mcset zh_tw  "Changed:" "最後變更狀態時間:"
	::msgcat::mcset zh_tw  "File Properties" "屬性"
	::msgcat::mcset zh_tw  "General" "一般"
	::msgcat::mcset zh_tw  "Group" "群組"
	::msgcat::mcset zh_tw  "Location:" "位置:"
	::msgcat::mcset zh_tw  "Modified:" "最後修改時間:"
	::msgcat::mcset zh_tw  "Name:" "檔名:"
	::msgcat::mcset zh_tw  "Other" "其它"
	::msgcat::mcset zh_tw  "Owner" "擁有者"
	::msgcat::mcset zh_tw  "Permissions" "權限"
	::msgcat::mcset zh_tw  "Read" "讀取"
	::msgcat::mcset zh_tw  "SID" "SID"
	::msgcat::mcset zh_tw  "Set GID" "設定GID"
	::msgcat::mcset zh_tw  "Set UID" "設定UID"
	::msgcat::mcset zh_tw  "Size:" "檔案大小:"
	::msgcat::mcset zh_tw  "Type:" "檔案類型:"
	::msgcat::mcset zh_tw  "Write" "寫入"
	::msgcat::mcset zh_tw  "execute" "執行"
	::msgcat::mcset zh_tw  "recursive apply" "套用到子資料夾"
}

namespace eval ::crowFileRelation {
	::msgcat::mcset zh_tw  "Add"  "增加"
	::msgcat::mcset zh_tw  "All"  "全部"
	::msgcat::mcset zh_tw  "Application"  "應用程式"
	::msgcat::mcset zh_tw  "Application:" "應用程式:"
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "File Extension:" "副檔名:"
	::msgcat::mcset zh_tw  "File Relation Setting"  "檔案關聯性"
	::msgcat::mcset zh_tw  "File types"  "檔案類型"
	::msgcat::mcset zh_tw  "Remove"  "刪除"
	::msgcat::mcset zh_tw  "Setting default"  "預設設定"
}

namespace eval ::crowFont {
	::msgcat::mcset zh_tw  "Apply"  "套用"
	::msgcat::mcset zh_tw  "Editor font"  "編輯字型"
	::msgcat::mcset zh_tw  "Fonts setting"  "字型設定"
	::msgcat::mcset zh_tw  "Large font"  "較大字型"
	::msgcat::mcset zh_tw  "Menu font"  "選單字型"
	::msgcat::mcset zh_tw  "Small font"  "較小字型"
	::msgcat::mcset zh_tw  "normal font"  "一般字型"
}

namespace eval ::crowGetDir {
	::msgcat::mcset zh_tw  "'%s' has been deleted from the file system!" "'%s' 已經由檔案系統中刪除!"
	::msgcat::mcset zh_tw  "Cancel" "取消"
	::msgcat::mcset zh_tw  "Choose Direcotry" "選擇目錄"
	::msgcat::mcset zh_tw  "Choose Folder First!" "請先選擇資料夾!"
	::msgcat::mcset zh_tw  "Error" "錯誤"
	::msgcat::mcset zh_tw  "Folder Already Exists!" "資料夾已經存在!"
	::msgcat::mcset zh_tw  "New Folder" "建立資料夾"
	::msgcat::mcset zh_tw  "Ok" "確定"
}

namespace eval ::crowIO {
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "Ok" "確定"
	::msgcat::mcset zh_tw  "Wrong argument!"  "錯誤的參數!"
	::msgcat::mcset zh_tw  "gets" "gets"
	::msgcat::mcset zh_tw  "read" "read"
}

namespace eval ::crowMacro {
	::msgcat::mcset zh_tw  "--Delete This Folder--" "--刪除這個資料夾--"
	::msgcat::mcset zh_tw  "Are you sure you want to delete macro?"  "您確定要刪除Macro?"
	::msgcat::mcset zh_tw  "Browse" "瀏覽"
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "Codes:" "程式碼:"
	::msgcat::mcset zh_tw  "Delete"  "刪除"
	::msgcat::mcset zh_tw  "Macro Name:" "Macro名稱:"
	::msgcat::mcset zh_tw  "Ok"  "確定"
	::msgcat::mcset zh_tw  "Operations"  "操作"
	::msgcat::mcset zh_tw  "Save Macro"  "儲存巨集(Macro)"
	::msgcat::mcset zh_tw  "Save Path:"  "儲存路徑:"
	::msgcat::mcset zh_tw  "System Define"  "系統預設"
	::msgcat::mcset zh_tw  "User Define"  "使用者預設"
}

namespace eval ::crowRC {
	::msgcat::mcset zh_tw  "Create fail!"  "建立失敗!"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
}

namespace eval ::crowSdx {
	::msgcat::mcset zh_tw  "%s Elapsed time ... %02s:%02s" "%s 經過時間 ... %02s:%02s"
	::msgcat::mcset zh_tw  "Browse" "瀏覽"
	::msgcat::mcset zh_tw  "Building starkit ..." "建立Starkit ..."
	::msgcat::mcset zh_tw  "Cancel" "取消"
	::msgcat::mcset zh_tw  "Do not compress files added to starkit" "不使用壓縮"
	::msgcat::mcset zh_tw  "Finish." "完成."
	::msgcat::mcset zh_tw  "Move '%s' -> '%s'" "搬移 '%s' -> '%s'"
	::msgcat::mcset zh_tw  "Ok" "確定"
	::msgcat::mcset zh_tw  "Options" "選項"
	::msgcat::mcset zh_tw  "SDX" "SDX"
	::msgcat::mcset zh_tw  "Save As.." "儲存"
	::msgcat::mcset zh_tw  "Save to:" "儲存目標:"
	::msgcat::mcset zh_tw  "Script:" "程式檔:"
	::msgcat::mcset zh_tw  "Size = %s (KB)" "大小 = %s (KB)"
	::msgcat::mcset zh_tw  "Starkit runtime not exists!" "執行環境檔案不存在!"
	::msgcat::mcset zh_tw  "VFS Directory:" "VFS資料夾:"
	::msgcat::mcset zh_tw  "Writable" "允許寫入"
	::msgcat::mcset zh_tw  "error" "錯誤"
	::msgcat::mcset zh_tw  "include runtime" "包含執行環境(runtime)"
}

namespace eval ::crowSyntax {
	::msgcat::mcset zh_tw  "Cancel" "取消"
	::msgcat::mcset zh_tw  "Ok" "確定"
}

namespace eval ::crowTde {
	::msgcat::mcset zh_tw  "CrowTDE Start success, thanks for use ^o^" "CrowTDE 啟動成功, 謝謝您的使用^o^"
	# New
	::msgcat::mcset zh_tw  "Loading plugin '%s' ..." "載入外掛 '%s' ..."
}

namespace eval ::crowThread {
	::msgcat::mcset zh_tw  "%s Finish" "%s 完成"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
	::msgcat::mcset zh_tw  "Interpreter '%s' not exists" "直執器 '%s' 不存在"
	::msgcat::mcset zh_tw  "Permission denied" "權限不足"
	::msgcat::mcset zh_tw  "Run %s ..." "執行 %s ..."
	::msgcat::mcset zh_tw  "You may not permission to execuate this file! Execuate force?" "您可能沒有權力執行這個檔案，您確定要執行嗎?"
}

namespace eval ::fmeDebugger {
	::msgcat::mcset zh_tw  "Add Watch" "增加監看變數"
	::msgcat::mcset zh_tw  "Add Watch..." "增加監看變數..."
	::msgcat::mcset zh_tw  "Breakpoints" "中斷點"
	::msgcat::mcset zh_tw  "Change Value..." "設定變數值..."
	::msgcat::mcset zh_tw  "Change value" "設定變數值"
	::msgcat::mcset zh_tw  "Currently-Visible Variables" "目前可視變數"
	::msgcat::mcset zh_tw  "Debug" "除錯"
	::msgcat::mcset zh_tw  "Debug Default Script..." "除錯預設Script..."
	::msgcat::mcset zh_tw  "Debug level" "除錯等級"
	::msgcat::mcset zh_tw  "Debug..." "除錯..."
	::msgcat::mcset zh_tw  "Deep" "深層除錯"
	::msgcat::mcset zh_tw  "Free go" "執行"
	::msgcat::mcset zh_tw  "Info" "訊息"
	::msgcat::mcset zh_tw  "Lines:" "行數:"
	::msgcat::mcset zh_tw  "Normal" "一般"
	::msgcat::mcset zh_tw  "Pause" "暫停"
	::msgcat::mcset zh_tw  "Position:" "位置:"
	::msgcat::mcset zh_tw  "Remove" "移除"
	::msgcat::mcset zh_tw  "Remove Watch" "移除監看變數"
	::msgcat::mcset zh_tw  "Script:" "Script:"
	::msgcat::mcset zh_tw  "Shallow" "簡單除錯"
	::msgcat::mcset zh_tw  "Start Debugger" "啟動除錯器"
	::msgcat::mcset zh_tw  "Step" "單步"
	::msgcat::mcset zh_tw  "Stop debugging" "停止除錯器"
	::msgcat::mcset zh_tw  "View" "檢視"
	::msgcat::mcset zh_tw  "Watch Variables" "監看變數"
	::msgcat::mcset zh_tw  "Watchpoint already exists!" "監看變數已經存在!"
}

namespace eval ::fmeDocView {
	::msgcat::mcset zh_tw  "Collapse" "折疊"
	::msgcat::mcset zh_tw  "Copy" "複製"
	::msgcat::mcset zh_tw  "Copy %d %s" "複製 %d %s"
	::msgcat::mcset zh_tw  "Document Viewer(%s)" "文件檢視器(%s)"
	::msgcat::mcset zh_tw  "Home" "首頁"
	::msgcat::mcset zh_tw  "Next" "下一頁"
	::msgcat::mcset zh_tw  "Previous" "上一頁"
	::msgcat::mcset zh_tw  "Top" "到文件頂端"
	::msgcat::mcset zh_tw  "View in new window" "開啟新視窗"
}

namespace eval ::fmeGenericSetting {
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Choose Tcl interpreter"  "選擇 Tcl 直譯器"
	::msgcat::mcset zh_tw  "Choose Tk interpreter"  "選擇 Tk 直譯器"
	::msgcat::mcset zh_tw  "Create new project"  "建立新專案"
	::msgcat::mcset zh_tw  "Debug Level" "除錯等級"
	::msgcat::mcset zh_tw  "Deep" "深層除錯"
	::msgcat::mcset zh_tw  "Do nothing"  "不做任何事"
	::msgcat::mcset zh_tw  "General Settings"  "一般設定"
	::msgcat::mcset zh_tw  "Interpreter"  "直譯器設定"
	::msgcat::mcset zh_tw  "Normal" "一般"
	::msgcat::mcset zh_tw  "Open last edit project"  "開啟最後編輯的專案"
	::msgcat::mcset zh_tw  "Shallow" "簡單錯除"
	::msgcat::mcset zh_tw  "Show startup page"  "顯示起始頁"
	::msgcat::mcset zh_tw  "Startup"  "啟動"
	::msgcat::mcset zh_tw  "Tcl Interpreter:"  "Tcl 直譯器:"
	::msgcat::mcset zh_tw  "Tk Interpreter:"  "Tk 直譯器:"
}

namespace eval ::fmeMenuBar {
	::msgcat::mcset zh_tw  "About..."  "關於..."
	::msgcat::mcset zh_tw  "Add %s" "加入 %s"
	::msgcat::mcset zh_tw  "Add Block Comment"  "插入註解"
	::msgcat::mcset zh_tw  "Add Task"  "新增工作項目"
	::msgcat::mcset zh_tw  "Add Watch..." "增加監看變數..."
	::msgcat::mcset zh_tw  "Adjust Tab Width" "調整Tab寬度"
	::msgcat::mcset zh_tw  "Build ' %s ' ..." "編譯 ' %s ' ..."
	::msgcat::mcset zh_tw  "Build ..." "編譯 ..."
	::msgcat::mcset zh_tw  "Build Project..." "編譯專案..."
	::msgcat::mcset zh_tw  "Close"  "關閉"
	::msgcat::mcset zh_tw  "Close All"  "關閉全部"
	::msgcat::mcset zh_tw  "Close Project"  "關閉專案"
	::msgcat::mcset zh_tw  "Collapse Toolbar"  "折疊工具列"
	::msgcat::mcset zh_tw  "Copy"  "複製"
	::msgcat::mcset zh_tw  "Cut"  "剪下"
	::msgcat::mcset zh_tw  "Debug" "除錯"
	::msgcat::mcset zh_tw  "Debug Default Script..." "除錯預設Script..."
	::msgcat::mcset zh_tw  "Debug level" "除錯等級"
	::msgcat::mcset zh_tw  "Debug..." "除錯..."
	::msgcat::mcset zh_tw  "Deep" "深層除錯"
	::msgcat::mcset zh_tw  "Default Disabled"  "預設禁能"
	::msgcat::mcset zh_tw  "Default Enabled"  "預設致能"
	::msgcat::mcset zh_tw  "Default script not exists!" "預設Script不存在!"
	::msgcat::mcset zh_tw  "Delete"  "刪除"
	::msgcat::mcset zh_tw  "Delete ' %s '" "刪除 ' %s '"
	::msgcat::mcset zh_tw  "Delete Completed Tasks"  "刪除完成的工作"
	::msgcat::mcset zh_tw  "Diabled All"  "全部禁能"
	::msgcat::mcset zh_tw  "Disabled Current Editor"  "目前的編輯區禁能"
	::msgcat::mcset zh_tw  "Edit"  "編輯"
	::msgcat::mcset zh_tw  "Editor Details"  "編輯區設定"
	::msgcat::mcset zh_tw  "Enabled All"  "全部致能"
	::msgcat::mcset zh_tw  "Enabled Current Editor"  "目前的編輯區致能"
	::msgcat::mcset zh_tw  "Exit"  "離開"
	::msgcat::mcset zh_tw  "Expand Toolbar"  "展開工具列"
	::msgcat::mcset zh_tw  "File"  "檔案"
	::msgcat::mcset zh_tw  "File Relation"  "檔案關聯性"
	::msgcat::mcset zh_tw  "Find/Replace..."  "搜尋/取代..."
	::msgcat::mcset zh_tw  "Folder..."  "資料夾..."
	::msgcat::mcset zh_tw  "Free Go" "自由執行"
	::msgcat::mcset zh_tw  "Help"  "說明"
	::msgcat::mcset zh_tw  "Import..."  "匯入..."
	::msgcat::mcset zh_tw  "Indent Selection"  "向右縮排"
	::msgcat::mcset zh_tw  "Insert Macro"  "插入巨集(Macro)"
	::msgcat::mcset zh_tw  "Jump To..."  "跳躍到..."
	::msgcat::mcset zh_tw  "Language"  "語言"
	::msgcat::mcset zh_tw  "Locale"  "位置"
	::msgcat::mcset zh_tw  "MP3 Directory - %s" "MP3 資料夾 - %s"
	::msgcat::mcset zh_tw  "MP3 Player Details"  "播放器 設定"
	::msgcat::mcset zh_tw  "New"  "新增"
	::msgcat::mcset zh_tw  "Next Page"  "下一頁"
	::msgcat::mcset zh_tw  "Normal" "一般"
	::msgcat::mcset zh_tw  "Open"  "開啟"
	::msgcat::mcset zh_tw  "Open File"  "開啟檔案"
	::msgcat::mcset zh_tw  "Open File..."  "開啟檔案..."
	::msgcat::mcset zh_tw  "Open Project..."  "開啟專案..."
	::msgcat::mcset zh_tw  "Options"  "選項"
	::msgcat::mcset zh_tw  "Paste"  "貼上"
	::msgcat::mcset zh_tw  "Pause" "暫停"
	::msgcat::mcset zh_tw  "Previous Page"  "上一頁"
	::msgcat::mcset zh_tw  "Print..."  "列印"
	::msgcat::mcset zh_tw  "Printer Setup*"  "列印機裝置*"
	::msgcat::mcset zh_tw  "Proc Details"  "程序更新"
	::msgcat::mcset zh_tw  "Project"  "專案"
	::msgcat::mcset zh_tw  "Project..."  "專案..."
	::msgcat::mcset zh_tw  "Properties..."  "屬性..."
	::msgcat::mcset zh_tw  "Raise"  "尋找"
	::msgcat::mcset zh_tw  "Recent Files"  "最近存取的檔案"
	::msgcat::mcset zh_tw  "Recent Projects"  "最近存取的專案"
	::msgcat::mcset zh_tw  "Redo"  "前一步"
	::msgcat::mcset zh_tw  "Refresh"  "重新整理"
	::msgcat::mcset zh_tw  "Refresh Interval (%s ms)" "更新週期 (%s ms)"
	::msgcat::mcset zh_tw  "Remove Block Comment"  "移除註解"
	::msgcat::mcset zh_tw  "Run Default Script..." "執行預設 Script..."
	::msgcat::mcset zh_tw  "Run..."  "執行..."
	::msgcat::mcset zh_tw  "Save"  "儲存"
	::msgcat::mcset zh_tw  "Save All"  "儲存全部"
	::msgcat::mcset zh_tw  "Save As"  "另存新檔"
	::msgcat::mcset zh_tw  "Save As ..."  "另存新檔..."
	::msgcat::mcset zh_tw  "Save Macro"  "儲存巨集(Macro)"
	::msgcat::mcset zh_tw  "Search Files..."  "搜尋檔案..."
	::msgcat::mcset zh_tw  "Search In Files..."  "在檔案中搜尋..."
	::msgcat::mcset zh_tw  "Select All"  "全選"
	::msgcat::mcset zh_tw  "Set ' %s ' As Default Script" "設定 ' %s ' 成預設執行"
	::msgcat::mcset zh_tw  "Settings..."  "設定"
	::msgcat::mcset zh_tw  "Shallow" "簡單除錯"
	::msgcat::mcset zh_tw  "Show Line Number"  "顯示行號"
	::msgcat::mcset zh_tw  "Show Syntax Helper" "顯示語法協助"
	::msgcat::mcset zh_tw  "Step" "單步"
	::msgcat::mcset zh_tw  "Stop" "停止"
	::msgcat::mcset zh_tw  "Syntax Check..." "語法檢查..."
	::msgcat::mcset zh_tw  "Syntax Highlight"  "語法標示"
	::msgcat::mcset zh_tw  "Tasks"  "工作"
	# New
	::msgcat::mcset zh_tw  "Test" "測試"
	::msgcat::mcset zh_tw  "Test(W)"  "測試(W)"
	::msgcat::mcset zh_tw  "The settings will apply at restart CrowTDE!"  "設定後重新啟動 CrowTDE!"
	::msgcat::mcset zh_tw  "Toolbar Details"  "工具列設定"
	::msgcat::mcset zh_tw  "Tools(T)"  "工具(T)"
	::msgcat::mcset zh_tw  "UnIndent Selection"  "向左縮排"
	::msgcat::mcset zh_tw  "Undo"  "後一步"
	::msgcat::mcset zh_tw  "Version Control*"  "版本控制*"
	::msgcat::mcset zh_tw  "Window"  "視窗"
	::msgcat::mcset zh_tw  "error!" "錯誤!"
	# New
	::msgcat::mcset zh_tw  "freewrap*" "freewrap*"
}

namespace eval ::fmeNagelfar {
	::msgcat::mcset zh_tw  "Choose File" "選擇檔案"
	::msgcat::mcset zh_tw  "Clear" "清除"
	::msgcat::mcset zh_tw  "Do Check" "執行語法檢查"
	::msgcat::mcset zh_tw  "File:" "檔案:"
	::msgcat::mcset zh_tw  "Save" "儲存"
	::msgcat::mcset zh_tw  "Save Output..." "儲存輸出..."
	# New
	::msgcat::mcset zh_tw  "Select File" "選擇檔案"
	::msgcat::mcset zh_tw  "Select File..." "選擇檔案..."
}

namespace eval ::fmePlayer {
	::msgcat::mcset zh_tw  "MP3 Folder"  "MP3 資料夾"
	::msgcat::mcset zh_tw  "MP3:"  "MP3:"
	::msgcat::mcset zh_tw  "Vol:"  "音量:"
}

namespace eval ::fmeProcManager {
	::msgcat::mcset zh_tw  "Error" "錯誤"
	::msgcat::mcset zh_tw  "Interval"  "間隔"
	::msgcat::mcset zh_tw  "Please specify Tcl interpreter first!" "請先設定您的Tcl直譯器!"
	::msgcat::mcset zh_tw  "View"  "檢視"
}

namespace eval ::fmeProjectManager {
	::msgcat::mcset zh_tw  "%s Open" "%s 開啟"
	::msgcat::mcset zh_tw  "'%s' already exists!" "'%s' 已經存在!"
	::msgcat::mcset zh_tw  "'%s' already exists." "'%s' 已經存在."
	::msgcat::mcset zh_tw  "'%s' has been deleted from the file system!" "'%s' 已經行檔案系統中刪除!"
	::msgcat::mcset zh_tw  "'%s' not exists!" "'%s' 不存在!"
	::msgcat::mcset zh_tw  "All"  "全部"
	::msgcat::mcset zh_tw  "Are you sure you want to delete '%s' from the file system ?" "您確定要從檔案系統中刪除 '%s' 嗎?"
	::msgcat::mcset zh_tw  "Build..." "編譯..."
	::msgcat::mcset zh_tw  "Cancel" "取消"
	::msgcat::mcset zh_tw  "Check Syntax*"  "語法確認*"
	::msgcat::mcset zh_tw  "Close Project"  "關閉專案"
	::msgcat::mcset zh_tw  "Confirm"  "確認"
	::msgcat::mcset zh_tw  "Copied %s" "複製 %s"
	::msgcat::mcset zh_tw  "Copy"  "複製"
	::msgcat::mcset zh_tw  "Cut"  "剪下"
	::msgcat::mcset zh_tw  "Cut %s" "Cut %s"
	::msgcat::mcset zh_tw  "Debug..." "除錯..."
	::msgcat::mcset zh_tw  "Default script not exists" "預設script不存在"
	::msgcat::mcset zh_tw  "Default script not specify!"  "預設script沒有指定!"
	::msgcat::mcset zh_tw  "Delete"  "刪除"
	::msgcat::mcset zh_tw  "Edit"  "編輯"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
	::msgcat::mcset zh_tw  "File Properties..."  "檔案屬性..."
	::msgcat::mcset zh_tw  "File copy fail!"  "檔案複製失敗!"
	::msgcat::mcset zh_tw  "File name invalid." "不正確的檔案名稱."
	::msgcat::mcset zh_tw  "Folder"  "資料夾"
	::msgcat::mcset zh_tw  "Folder already exists!"  "資料夾已經存在!"
	::msgcat::mcset zh_tw  "Import to : (%s)" "匯入位置 : (%s)"
	::msgcat::mcset zh_tw  "Location : %s" "位置 : %s"
	::msgcat::mcset zh_tw  "New Folder"  "新增資料夾"
	::msgcat::mcset zh_tw  "New Item"  "新增項目"
	::msgcat::mcset zh_tw  "No copy target"  "沒有複製目標"
	::msgcat::mcset zh_tw  "Ok" "確定"
	::msgcat::mcset zh_tw  "Open" "開啟"
	::msgcat::mcset zh_tw  "Open As..." "外部程式開啟..."
	::msgcat::mcset zh_tw  "Open Project"  "開啟專案"
	::msgcat::mcset zh_tw  "Others..."  "其他..."
	::msgcat::mcset zh_tw  "Paste"  "貼上"
	::msgcat::mcset zh_tw  "Please specify Tcl or Tk interpreter first!" "請先設定您的Tcl或Tk直譯器!"
	::msgcat::mcset zh_tw  "Project - %s" "專案 - %s"
	::msgcat::mcset zh_tw  "Project Properties..."  "專案屬性..."
	::msgcat::mcset zh_tw  "Rename"  "重新命名"
	::msgcat::mcset zh_tw  "Rename fail!"  "重新命名失敗!"
	::msgcat::mcset zh_tw  "Replace" "覆蓋"
	::msgcat::mcset zh_tw  "Run..."  "執行"
	::msgcat::mcset zh_tw  "Save Project.." "儲存專案.."
	::msgcat::mcset zh_tw  "Set As Default Script"  "設定成預設Script"
	::msgcat::mcset zh_tw  "Syntax Check..." "語法檢查..."
	::msgcat::mcset zh_tw  "The folder already contains a file named %s" "資料夾中已經存在 %s"
	::msgcat::mcset zh_tw  "The operation need close current project. Close project ?"  "這個動作需要關閉目前的專案. 是否關閉專案 ?"
	::msgcat::mcset zh_tw  "refresh"  "重新整理"
}

namespace eval ::fmeStatusBar {
	::msgcat::mcset zh_tw  "Lines"  "行數"
	::msgcat::mcset zh_tw  "Pos"  "位置"
}

namespace eval ::fmeTabEditor {
	::msgcat::mcset zh_tw  "'%s' has not save. save it ?" "'%s' 還沒有儲存,您要儲存嗎 ?"
	::msgcat::mcset zh_tw  "Cancal"  "取消"
	::msgcat::mcset zh_tw  "Copy %s - %s" "複製 %s - %s"
	::msgcat::mcset zh_tw  "Cut %s - %s" "剪下 %s - %s"
	::msgcat::mcset zh_tw  "No Copy Region"  "沒有複製目標"
	::msgcat::mcset zh_tw  "No Cut Region"  "沒有剪下目標"
	::msgcat::mcset zh_tw  "Paste"  "貼上"
	::msgcat::mcset zh_tw  "Print"  "列印"
	::msgcat::mcset zh_tw  "Print Command:"  "執行列印:"
}

namespace eval ::fmeTabMgr {
	::msgcat::mcset zh_tw  "Debug" "除錯"
	::msgcat::mcset zh_tw  "File"  "檔案"
	::msgcat::mcset zh_tw  "Help"  "文件"
	::msgcat::mcset zh_tw  "Proc"  "程序"
}

namespace eval ::fmeTask {
	::msgcat::mcset zh_tw  "Add Task"  "新增工作項目"
	::msgcat::mcset zh_tw  "All" "全部"
	::msgcat::mcset zh_tw  "Are you sure you want to delete %%d tasks?" "您確定要刪除 %%d 個工作項目嗎?"
	::msgcat::mcset zh_tw  "Change State" "切換狀態"
	::msgcat::mcset zh_tw  "Delete"  "刪除"
	::msgcat::mcset zh_tw  "Delete Completed Tasks"  "刪除完成的工作"
	::msgcat::mcset zh_tw  "Delete Task"  "刪除工作"
	::msgcat::mcset zh_tw  "Description"  "描述"
	::msgcat::mcset zh_tw  "Do you want to delete completed task ?"  "您要刪除完成的工作嗎?"
	::msgcat::mcset zh_tw  "Do you want to delete task ?"  "您要刪除工作嗎 ?"
	::msgcat::mcset zh_tw  "Edit"  "編輯"
	::msgcat::mcset zh_tw  "Find" "尋找"
	::msgcat::mcset zh_tw  "Finished" "已完成"
	::msgcat::mcset zh_tw  "Hide Completed Tasks" "隱藏已完成的工作項目"
	::msgcat::mcset zh_tw  "In Progress" "處理中"
	::msgcat::mcset zh_tw  "Not Started" "未處理"
	::msgcat::mcset zh_tw  "Refresh"  "重新整理"
	::msgcat::mcset zh_tw  "Reset" "重置"
	::msgcat::mcset zh_tw  "Search:" "蒐尋:"
	::msgcat::mcset zh_tw  "State"  "狀態"
	::msgcat::mcset zh_tw  "Task Delete"  "刪除工作"
	::msgcat::mcset zh_tw  "Task already hidden!" "工作項目已經隱藏!"
	::msgcat::mcset zh_tw  "Time"  "加入時間"
}

namespace eval ::fmeTaskMgr {
	::msgcat::mcset zh_tw  "Debug" "除錯"
	::msgcat::mcset zh_tw  "Nagelfar" "Nagelfar"
	::msgcat::mcset zh_tw  "Tasks"  "工作"
	::msgcat::mcset zh_tw  "TkCon"  "TkCon"
}

namespace eval ::fmeToolbar {
	::msgcat::mcset zh_tw  "Add Block Comment"  "插入註解"
	::msgcat::mcset zh_tw  "Backward"  "往後搜尋"
	::msgcat::mcset zh_tw  "Case Sensitive"  "符合大小寫"
	::msgcat::mcset zh_tw  "Copy"  "複製"
	::msgcat::mcset zh_tw  "Cut"  "剪下"
	::msgcat::mcset zh_tw  "Debug Default Script..." "除錯預設Script..."
	# New
	::msgcat::mcset zh_tw  "Debug current file" "除錯目前的檔案"
	# New
	::msgcat::mcset zh_tw  "Debug project" "除錯專案"
	::msgcat::mcset zh_tw  "Debug..." "除錯..."
	::msgcat::mcset zh_tw  "File..."  "檔案..."
	::msgcat::mcset zh_tw  "Find"  "搜尋"
	::msgcat::mcset zh_tw  "Find Options"  "搜尋設定"
	::msgcat::mcset zh_tw  "Folder..."  "資料夾..."
	::msgcat::mcset zh_tw  "Ident Selection"  "向右縮排"
	::msgcat::mcset zh_tw  "MP3 Player" "MP3 播放器"
	::msgcat::mcset zh_tw  "New"  "新增"
	::msgcat::mcset zh_tw  "Open"  "開啟"
	::msgcat::mcset zh_tw  "Open File"  "開啟檔案"
	::msgcat::mcset zh_tw  "Paste"  "貼上"
	::msgcat::mcset zh_tw  "Print current editor..." "列印目前編輯區..."
	::msgcat::mcset zh_tw  "Project..."  "專案..."
	::msgcat::mcset zh_tw  "Redo"  "下一步"
	::msgcat::mcset zh_tw  "Regular Expression"  "正規表示式"
	::msgcat::mcset zh_tw  "Remove Block Comment"  "移除註解"
	::msgcat::mcset zh_tw  "Run Project..."  "執行專案..."
	::msgcat::mcset zh_tw  "Run..."  "執行"
	::msgcat::mcset zh_tw  "Save"  "儲存"
	::msgcat::mcset zh_tw  "Save All"  "儲存全部"
	::msgcat::mcset zh_tw  "Search files" "搜尋檔案"
	::msgcat::mcset zh_tw  "Search in files" "在檔案中搜尋"
	::msgcat::mcset zh_tw  "Start Debugger" "啟動除錯器"
	::msgcat::mcset zh_tw  "Stop" "關閉"
	::msgcat::mcset zh_tw  "Stop '%s'" "關閉 '%s'"
	::msgcat::mcset zh_tw  "Syntax check..." "語法檢查..."
	::msgcat::mcset zh_tw  "UnIdent Selection"  "向左縮排"
	::msgcat::mcset zh_tw  "Undo"  "上一步"
}

namespace eval ::frmAbout {
	::msgcat::mcset zh_tw  "About CrowTDE"  "關於 CrowTDE"
	# New
	::msgcat::mcset zh_tw  "Copyright (C) 2006-2007 Tai, Yuan-Liang & Zheng, Shao-Huan" "Copyright (C) 2006-2007 戴源良 & 鄭紹歡"
	::msgcat::mcset zh_tw  "Credits" "致謝"
	::msgcat::mcset zh_tw  "CrowTDE License" "CrowTDE 授權條款"
	::msgcat::mcset zh_tw  "CrowTDE is an open source Tcl/Tk development %s environment written in Tcl/Tk. Its purposes is to provide a %s convenient environment for Tcl/Tk programmers." "CrowTDE 是一個Tcl/Tk的開發環境,它的目的是希望提供一個方便的開發環境給Tcl/Tk的程式開發者."
	::msgcat::mcset zh_tw  "Exit" "離開"
	::msgcat::mcset zh_tw  "German - Michael Schlenker <mic42@user.sourceforge.net> %s" "German - Michael Schlenker <mic42@user.sourceforge.net> %s"
	# New
	::msgcat::mcset zh_tw  "Italian - Diego <siarodx@gmail.com> %s" "Italian - Diego <siarodx@gmail.com> %s"
	::msgcat::mcset zh_tw  "License" "授權條款"
	::msgcat::mcset zh_tw  "License:" "授權條款:"
	::msgcat::mcset zh_tw  "Traditional Chinese - Zang, Ke-Yuan <jarry@crow.ee.stut.edu.tw> %s" "中文化工作(Taiwan) 張克遠 <jarry@crow.ee.stut.edu.tw> %s"
	::msgcat::mcset zh_tw  "Translators" "翻譯"
	::msgcat::mcset zh_tw  "Visit : http://crow.ee.stut.edu.tw/dai/crowtde/" "參觀 : http://crow.ee.stut.edu.tw/dai/crowtde/"
}

namespace eval ::frmCheckSave {
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "No"  "否"
	::msgcat::mcset zh_tw  "Save"  "儲存"
	::msgcat::mcset zh_tw  "Save files ?" "儲存檔案 ?"
	::msgcat::mcset zh_tw  "Yes"  "是"
}

namespace eval ::frmFirst {
	::msgcat::mcset zh_tw  "Basic Settings"  "基本設定"
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Information"  "信息"
	::msgcat::mcset zh_tw  "Language:"  "語言:"
	::msgcat::mcset zh_tw  "Ok"  "完成"
	::msgcat::mcset zh_tw  "Open File"  "開啟檔案"
	::msgcat::mcset zh_tw  "Tcl Interpreter:"  "Tcl 直譯器:"
	::msgcat::mcset zh_tw  "Tk Interpreter:"  "Tk 直譯器:"
	::msgcat::mcset zh_tw  "You are first time running CrowTDE.%s Please configure your basic run-time environment." "您是第一次啟動CrowTDE.%s 請輸入一些基本資訊."
	::msgcat::mcset zh_tw  "You can configure more details from 'Main Menu->Options->Settings' ."  "您可以在 '主選單->選單->設定' 作詳細的設定."
}

namespace eval ::frmNewProject {
	::msgcat::mcset zh_tw  "'%s' already exists." "'%s' 已經存在."
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "Create"  "建立"
	::msgcat::mcset zh_tw  "Default Script:"  "預設Script:"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
	::msgcat::mcset zh_tw  "Interpreter"  "直譯器"
	::msgcat::mcset zh_tw  "Interpreter:"  "直譯器:"
	::msgcat::mcset zh_tw  "New Project"  "新增專案"
	::msgcat::mcset zh_tw  "Please choose template first!"  "請選擇第一個樣板!"
	::msgcat::mcset zh_tw  "Project Name:"  "專案名稱:"
	::msgcat::mcset zh_tw  "Template:"  "樣板:"
	::msgcat::mcset zh_tw  "Workspace"  "工作區"
	::msgcat::mcset zh_tw  "Workspace:"  "工作區:"
}

namespace eval ::frmProjectProperty {
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "Default Script:"  "預設Script:"
	::msgcat::mcset zh_tw  "Interpreter"  "直譯器"
	::msgcat::mcset zh_tw  "Interpreter:"  "直譯器:"
	::msgcat::mcset zh_tw  "Ok"  "完成"
	::msgcat::mcset zh_tw  "Project Name:"  "專案名稱:"
	::msgcat::mcset zh_tw  "Project Properties"  "專案屬性"
	::msgcat::mcset zh_tw  "Workspace:"  "工作區:"
}

namespace eval ::frmSearchFiles {
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Choose Directory"  "選擇目錄"
	::msgcat::mcset zh_tw  "Directory:"  "目錄:"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
	::msgcat::mcset zh_tw  "File name:"  "檔案名稱:"
	::msgcat::mcset zh_tw  "Finish %s items found." "搜尋完成,找到 %s 個項目."
	::msgcat::mcset zh_tw  "Keyword can't empty!"  "關鍵字不能空白!"
	::msgcat::mcset zh_tw  "Search directory not valid!"  "無效的搜尋目錄!"
	::msgcat::mcset zh_tw  "Search files" "搜尋檔案"
	::msgcat::mcset zh_tw  "Search hidden files & folders"  "搜尋隱藏檔案與資料夾"
	::msgcat::mcset zh_tw  "Start"  "啟動"
	::msgcat::mcset zh_tw  "Stop"  "停止"
}

namespace eval ::frmSearchInFiles {
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Case Sensitive"  "符合大小寫"
	::msgcat::mcset zh_tw  "Choose Directory"  "選取目錄"
	::msgcat::mcset zh_tw  "Directory"  "目錄"
	::msgcat::mcset zh_tw  "Error"  "錯誤"
	::msgcat::mcset zh_tw  "Filter:"  "篩選:"
	::msgcat::mcset zh_tw  "Keyword can't empty!"  "關鍵字不能空白!"
	::msgcat::mcset zh_tw  "Keyword:"  "關鍵字:"
	::msgcat::mcset zh_tw  "Regular Expression"  "正規表示式"
	::msgcat::mcset zh_tw  "Search directory not valid!"  "無效的搜尋目錄!"
	::msgcat::mcset zh_tw  "Search hidden files & folders"  "搜尋隱藏的資料夾與檔案"
	::msgcat::mcset zh_tw  "Search in files" "在檔案中搜尋"
	::msgcat::mcset zh_tw  "Start"  "啟動"
	::msgcat::mcset zh_tw  "Stop"  "停止"
}

namespace eval ::frmSetting {
	::msgcat::mcset zh_tw  "CrowTDE configuration" "CrowTDE組態工具"
	::msgcat::mcset zh_tw  "Editor Settings" "編輯器設定"
	::msgcat::mcset zh_tw  "Exit"  "離開"
	::msgcat::mcset zh_tw  "File Settings" "檔案設定"
	::msgcat::mcset zh_tw  "Fonts"  "字型設定"
	::msgcat::mcset zh_tw  "General"  "一般設定"
}

namespace eval ::frmStartPage {
	::msgcat::mcset zh_tw  "Browse..."  "瀏覽..."
	::msgcat::mcset zh_tw  "Cancel"  "取消"
	::msgcat::mcset zh_tw  "Create New Project..."  "建立新專案..."
	::msgcat::mcset zh_tw  "CrowTDE Start Page"  "CrowTDE 啟動事件"
	::msgcat::mcset zh_tw  "Ok"  "完成"
	::msgcat::mcset zh_tw  "Open Last Project (%s)" "開啟最後編輯的專案 (%s)"
	::msgcat::mcset zh_tw  "Open Project"  "開啟專案"
	::msgcat::mcset zh_tw  "Please Choose Function"  "請選取功能"
	::msgcat::mcset zh_tw  "Project:"  "專案:"
}

namespace eval ::svnWrapper {
	# New
	::msgcat::mcset zh_tw  "...ok!" "...ok!"
	# New
	::msgcat::mcset zh_tw  "Add" "Add"
	# New
	::msgcat::mcset zh_tw  "Are you want to remove '%s' propeties?" "Are you want to remove '%s' properties?"
	# New
	::msgcat::mcset zh_tw  "Cancel" "Cancel"
	# New
	::msgcat::mcset zh_tw  "Check for modifications" "Check for modifications"
	# New
	::msgcat::mcset zh_tw  "Checkout" "Checkout"
	# New
	::msgcat::mcset zh_tw  "Checkout directory:" "Checkout Directory:"
	# New
	::msgcat::mcset zh_tw  "Checkout from SVN" "Checkout from SVN"
	# New
	::msgcat::mcset zh_tw  "Choose Directory" "Choose Directory"
	# New
	::msgcat::mcset zh_tw  "Clean up" "Clean up"
	# New
	::msgcat::mcset zh_tw  "Commit" "Commit"
	# New
	::msgcat::mcset zh_tw  "Commit to : %s" "Commit to : %s"
	# New
	::msgcat::mcset zh_tw  "Delete" "Delete"
	# New
	::msgcat::mcset zh_tw  "Directory can't empty." "Directory can't empty."
	# New
	::msgcat::mcset zh_tw  "Directory:" "Directory:"
	# New
	::msgcat::mcset zh_tw  "Edit" "Edit"
	# New
	::msgcat::mcset zh_tw  "Error!" "Error!"
	# New
	::msgcat::mcset zh_tw  "Export" "Export"
	# New
	::msgcat::mcset zh_tw  "Export: %s" "Export: %s"
	# New
	::msgcat::mcset zh_tw  "File list is empty!" "File list is empty!"
	# New
	::msgcat::mcset zh_tw  "HEAD revision" "HEAD revision"
	# New
	::msgcat::mcset zh_tw  "Import" "Import"
	# New
	::msgcat::mcset zh_tw  "Import Message:" "Import Message:"
	# New
	::msgcat::mcset zh_tw  "Include ignored files" "Include ignored files"
	# New
	::msgcat::mcset zh_tw  "Include unversion file(s)" "Include unversion file(s)"
	# New
	::msgcat::mcset zh_tw  "Login" "Login"
	# New
	::msgcat::mcset zh_tw  "Message : " "Message : "
	# New
	::msgcat::mcset zh_tw  "Move" "Move"
	# New
	::msgcat::mcset zh_tw  "Move to:" "Move to:"
	# New
	::msgcat::mcset zh_tw  "No files were changed or added since the last commit." "No files were changed or added since the last commit."
	# New
	::msgcat::mcset zh_tw  "Not thing to do." "Not thing to do."
	# New
	::msgcat::mcset zh_tw  "Ok" "Ok"
	# New
	::msgcat::mcset zh_tw  "Passwd:" "Passwd:"
	# New
	::msgcat::mcset zh_tw  "Please select a property first!" "Please select a property first!"
	# New
	::msgcat::mcset zh_tw  "Please wait" "Please wait"
	# New
	::msgcat::mcset zh_tw  "Properties" "Properties"
	# New
	::msgcat::mcset zh_tw  "Property" "Property"
	# New
	::msgcat::mcset zh_tw  "Property :" "Property :"
	# New
	::msgcat::mcset zh_tw  "Remove" "Remove"
	# New
	::msgcat::mcset zh_tw  "Remove properties" "Remove properties"
	# New
	::msgcat::mcset zh_tw  "Rename" "Rename"
	# New
	::msgcat::mcset zh_tw  "Repository:" "Repository:"
	# New
	::msgcat::mcset zh_tw  "Resolved" "Resolved"
	# New
	::msgcat::mcset zh_tw  "Revert" "Revert"
	# New
	::msgcat::mcset zh_tw  "Revision" "Revision"
	# New
	::msgcat::mcset zh_tw  "SVN Update" "SVN Update"
	# New
	::msgcat::mcset zh_tw  "Status" "Status"
	# New
	::msgcat::mcset zh_tw  "Subversion" "Subversion"
	# New
	::msgcat::mcset zh_tw  "Svn" "Svn"
	# New
	::msgcat::mcset zh_tw  "Target : %s" "Target : %s"
	# New
	::msgcat::mcset zh_tw  "URL can't empty." "URL can't empty."
	# New
	::msgcat::mcset zh_tw  "URL of repository:" "URL of repository:"
	# New
	::msgcat::mcset zh_tw  "Update" "Update"
	# New
	::msgcat::mcset zh_tw  "Username:" "Username:"
	# New
	::msgcat::mcset zh_tw  "Value" "Value"
	# New
	::msgcat::mcset zh_tw  "Value :" "Value :"
	# New
	::msgcat::mcset zh_tw  "error" "error"
	# New
	::msgcat::mcset zh_tw  "update" "update"
}

namespace eval ::crowTemplate {
	#New
	::msgcat::mcset zh_tw "Empty file" "空白檔案"
	#New
	::msgcat::mcset zh_tw "Tcl Package" "Tcl套件"
	
	#New
	::msgcat::mcset zh_tw "Create an empty project." "空白專案"	
	# New
	::msgcat::mcset zh_tw  "Checkout project from SVN Repository." "由SVN檔案庫取出專案."
	# New
	::msgcat::mcset zh_tw  "SVN Project" "SVN 專案"
}