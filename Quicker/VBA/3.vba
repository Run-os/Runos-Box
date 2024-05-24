Sub SetFont()
    With selection.Font
        .NameFarEast = "{中文字体}"
        .Name = "{英文字体}"
        .Size = {字体磅值}
        .Bold = {加粗}
        .Color = RGB(0, 0, 0)
    end with

    with selection.ParagraphFormat
        .PageBreakBefore = {段前分页}        ' 设置段前分页
        .KeepWithNext = {与下段同页}       ' 设置与下段同页
        .LineSpacingRule = "{行距}"          ' 0=1倍，1=1.5倍，2=2倍
        .SpaceBefore = "{段前间距}"      
        .SpaceAfter = "{段后间距}"       
        .CharacterUnitFirstLineIndent = {首行缩进}  '0= 不缩进，1=缩进1字符，2=缩进2字符
        If {大纲级别} = 0 Then
            .OutlineLevel = wdOutlineLevelBodyText
        ElseIf {大纲级别} = 1 Then
            .OutlineLevel = wdOutlineLevel1
        ElseIf {大纲级别} = 2 Then
            .OutlineLevel = wdOutlineLevel2
        ElseIf {大纲级别} = 3 Then
            .OutlineLevel = wdOutlineLevel3
        ElseIf {大纲级别} = 4 Then
            .OutlineLevel = wdOutlineLevel4
        ElseIf {大纲级别} = 5 Then
            .OutlineLevel = wdOutlineLevel5
        ElseIf {大纲级别} = 6 Then
            .OutlineLevel = wdOutlineLevel6
        End If
    End With

End Sub
