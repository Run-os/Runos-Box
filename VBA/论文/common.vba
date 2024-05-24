Function 论文setting(样式名, 字体, 字体大小, 加粗, 段前分页, 与下段同页, 行距, 段前段后间距,首行缩进,大纲级别)
    Dim objStyle

    ' 尝试获取“标题1”样式
    On Error Resume Next ' 如果样式不存在，避免错误中断
    Set objStyle = ActiveDocument.Styles(样式名)
    On Error GoTo 0 ' 重置错误处理
    
    ' 如果“标题1”样式不存在，则创建它
    If objStyle Is Nothing Then
        ActiveDocument.Styles.Add Name:=样式名, Type:=wdStyleTypeParagraph
        Set objStyle = ActiveDocument.Styles(样式名)
    End If

    ActiveDocument.Styles(样式名).AutomaticallyUpdate = False
    ' 设置字体属性
    With objStyle.Font
        .NameFarEast = 字体      ' 设置中文字体
        .Name = "Times New Roman" ' 设置英文字体
        .Size = 字体大小                ' 设置字体大小为小三（15磅）
        .Bold = 加粗              ' 设置字体加粗
        .Color = RGB(0, 0, 0)
        
    End With

    With objStyle.ParagraphFormat  ' 设置段落属性
        .PageBreakBefore = 段前分页    ' 设置段前分页
        .KeepWithNext = 与下段同页       ' 设置与下段同页
        .LineSpacingRule = 行距     ' 设置1.5倍行距
        .SpaceBefore = 段前段后间距        ' 设置段前间距为0.5行
        .SpaceAfter = 段前段后间距         ' 设置段后间距为0.5行
        .CharacterUnitFirstLineIndent = 首行缩进
        if 大纲级别 = 0 Then
            .OutlineLevel = wdOutlineLevelBodyText
        ElseIf 大纲级别 = 1 Then
            .OutlineLevel = wdOutlineLevel1
        ElseIf 大纲级别 = 2 Then
            .OutlineLevel = wdOutlineLevel2
        ElseIf 大纲级别 = 3 Then
            .OutlineLevel = wdOutlineLevel3
        ElseIf 大纲级别 = 4 Then
            .OutlineLevel = wdOutlineLevel4
        ElseIf 大纲级别 = 5 Then
            .OutlineLevel = wdOutlineLevel5
        ElseIf 大纲级别 = 6 Then
            .OutlineLevel = wdOutlineLevel6
        End If
    End With

    ActiveDocument.Styles(样式名).NoSpaceBetweenParagraphsOfSameStyle = False
    With ActiveDocument.Styles(样式名)
        .AutomaticallyUpdate = False
        If 样式名 <> "正文" Then
            .BaseStyle = "正文"
        End If
        .NextParagraphStyle = "正文"
    End With
End Function

Sub 论文()
    Dim 样式名
    Dim 字体
    Dim 字体大小
    Dim 加粗
    Dim 段前分页
    Dim 与下段同页
    Dim 行距
    Dim 段前段后间距
    dim 首行缩进
    dim 大纲级别

    样式名 = "正文"
    字体 = "宋体" 
    字体大小 = 12   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    加粗 = False
    段前分页 = False
    与下段同页 = False
    行距 = 1       ' 0=1倍，1=1.5倍，2=2倍
    段前段后间距 = 0 
    首行缩进 = 2
    Call 论文setting(样式名, 字体, 字体大小, 加粗, 段前分页, 与下段同页, 行距, 段前段后间距,首行缩进,大纲级别)
    
    样式名 = "标题 1"
    字体 = "黑体"
    字体大小 = 15   '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    加粗 = True
    段前分页 = True
    与下段同页 = True
    行距 = 1       ' 0=1倍，1=1.5倍，2=2倍
    段前段后间距 = 0.5 
    首行缩进 = 0
    Call 论文setting(样式名, 字体, 字体大小, 加粗, 段前分页, 与下段同页, 行距, 段前段后间距,首行缩进,大纲级别)

    样式名 = "标题 2"
    字体 = "黑体"
    字体大小 = 12  '18=小二 16=三号 15=小三 14=四号 12=小四 10.5=五号 9=小五
    加粗 = True
    段前分页 = False
    与下段同页 = True
    行距 = 1       ' 0=1倍，1=1.5倍，2=2倍
    段前段后间距 = 0 
    首行缩进 = 0
    Call 论文setting(样式名, 字体, 字体大小, 加粗, 段前分页, 与下段同页, 行距, 段前段后间距,首行缩进,大纲级别)
End Sub




