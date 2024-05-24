Function 论文setting(dict)
    Dim objStyle
    '新建 图片样式 判断是否存在
    On Error Resume Next  ' 暂时禁用错误处理
    styleExists = Not (ActiveDocument.Styles(dict("样式名")) Is Nothing)
    On Error GoTo 0       ' 恢复正常的错误处理
 
    If  styleExists Then
        Set objStyle = ActiveDocument.Styles(dict("样式名"))
    ElseIf Not styleExists Then
        ActiveDocument.Styles.Add Name:=dict("样式名"), Type:=wdStyleTypeParagraph
        Set objStyle = ActiveDocument.Styles(dict("样式名"))
    End If

    ' 设置样式
    objStyle.AutomaticallyUpdate = False
    
    With objStyle.Font ' 设置字体属性
        .NameFarEast = dict("字体") 
        .Name = "Times New Roman" 
        .Size = dict("字体大小")    
        .Bold = dict("加粗")        
        .Color = RGB(0, 0, 0)
    End With

    With objStyle.ParagraphFormat  ' 段落格式
        .PageBreakBefore = dict("段前分页")
        .KeepWithNext = dict("与下段同页") 
        .LineSpacingRule = dict("行距") 
        .SpaceBefore = dict("段前间距")    
        .SpaceAfter = dict("段后间距")     
        .CharacterUnitFirstLineIndent = dict("首行缩进")
        .AutoAdjustRightIndent = True   ' 启用自动右缩进调整。
        .DisableLineHeightGrid = False  ' 不禁用行高网格。

        If dict("大纲级别") = 0 Then
            .OutlineLevel = wdOutlineLevelBodyText
        ElseIf dict("大纲级别") = 1 Then
            .OutlineLevel = wdOutlineLevel1
        ElseIf dict("大纲级别") = 2 Then
            .OutlineLevel = wdOutlineLevel2
        ElseIf dict("大纲级别") = 3 Then
            .OutlineLevel = wdOutlineLevel3
        ElseIf dict("大纲级别") = 4 Then
            .OutlineLevel = wdOutlineLevel4
        ElseIf dict("大纲级别") = 5 Then
            .OutlineLevel = wdOutlineLevel5
        ElseIf dict("大纲级别") = 6 Then
            .OutlineLevel = wdOutlineLevel6
        End If
    End With

    ActiveDocument.Styles(dict("样式名")).NoSpaceBetweenParagraphsOfSameStyle = False
    With ActiveDocument.Styles(dict("样式名"))
        .AutomaticallyUpdate = False
        If dict("样式名") <> "正文" Then
            .BaseStyle = "正文"
        End If
    
        .NextParagraphStyle = "正文"
    End With
End Function

Sub 论文()
    Dim dict As Object
    Set dict = CreateObject("scripting.dictionary")
    dict.Add "样式名", "标题 1"
    dict.Add "字体", "宋体"
    dict.Add "字体大小", "12"
    dict.Add "加粗", True
    dict.Add "段前分页", False
    dict.Add "与下段同页", True
    dict.Add "段后间距", 0.5
    dict.Add "段前间距", 0.5
    dict.Add "首行缩进", 2
    dict.Add "大纲级别", 2
    dict.Add "行距", 1

    dict("样式名") = "正文"
    dict("字体") = "宋体"
    dict("字体大小") = 12     '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    dict("加粗") = False
    dict("段前分页") = False
    dict("与下段同页") = False
    dict("行距") = 1        ' 0=1倍，1=1.5倍，2=2倍
    dict("段后间距") = 0
    dict("段前间距") = 0
    dict("首行缩进") = 2      '0= 不缩进，1=缩进1字符，2=缩进2字符
    dict("大纲级别") = 0      ' 0=正文，1=一级标题，2=二级标题，3=三级标题，4=四级标题，5=五级标题，6=六级标题
    Call 论文setting(dict)

    dict("样式名") = "标题 1"
    dict("字体") = "黑体"
    dict("字体大小") = 15   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    dict("加粗") = True
    dict("段前分页") = True
    dict("与下段同页") = True
    dict("行距") = 1       ' 0=1倍，1=1.5倍，2=2倍
    dict("段后间距") = 0.5
    dict("段前间距") = 0.5
    dict("首行缩进") = 0      '0= 不缩进，1=缩进1字符，2=缩进2字符
    dict("大纲级别") = 1    ' 0=正文，1=一级标题，2=二级标题，3=三级标题，4=四级标题，5=五级标题，6=六级标题
    Call 论文setting(dict)

    dict("样式名") = "标题 2"
    dict("字体") = "黑体"
    dict("字体大小") = 12   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    dict("加粗") = True
    dict("段前分页") = False
    dict("与下段同页") = True
    dict("行距") = 1        ' 0=1倍，1=1.5倍，2=2倍
    dict("段后间距") = 0.5
    dict("段前间距") = 0.5
    dict("首行缩进") = 0     '0= 不缩进，1=缩进1字符，2=缩进2字符
    dict("大纲级别") = 2    ' 0=正文，1=一级标题，2=二级标题，3=三级标题，4=四级标题，5=五级标题，6=六级标题
    Call 论文setting(dict)

    dict("样式名") = "标题 3"
    dict("字体") = "黑体"
    dict("字体大小") = 12   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    dict("加粗") = False
    dict("段前分页") = False
    dict("与下段同页") = True
    dict("行距") = 1        ' 0=1倍，1=1.5倍，2=2倍
    dict("段后间距") = 0.5
    dict("段前间距") = 0.5
    dict("首行缩进") = 0     '0= 不缩进，1=缩进1字符，2=缩进2字符
    dict("大纲级别") = 3    ' 0=正文，1=一级标题，2=二级标题，3=三级标题，4=四级标题，5=五级标题，6=六级标题
    Call 论文setting(dict)

    dict("样式名") = "论文题注"
    dict("字体") = "宋体"
    dict("字体大小") = 10.5   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    dict("加粗") = False
    dict("段前分页") = False
    dict("与下段同页") = True
    dict("行距") = 1        ' 0=1倍，1=1.5倍，2=2倍
    dict("段后间距") = 0
    dict("段前间距") = 0
    dict("首行缩进") = 0     '0= 不缩进，1=缩进1字符，2=缩进2字符
    dict("大纲级别") = 0    ' 0=正文，1=一级标题，2=二级标题，3=三级标题，4=四级标题，5=五级标题，6=六级标题
    Call 论文setting(dict)
End Sub