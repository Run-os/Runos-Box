Sub Macro2()
'
' Macro2 Macro
' 宏由 Liuyz 录制，时间: 2024/05/13
'

'
    With ActiveDocument.Styles.Item("标题 2")
        .Font.NameFarEast = "Cambria"
        .Font.NameFarEast = "Cambria"
        .Font.NameFarEast = "Cambria"
        .Font.NameFarEast = "Cambria"
        .NextParagraphStyle = "标题 2"
        With .Font
            .NameAscii = "Times New Roman"
            .NameOther = "Times New Roman"
            .NameFarEast = "宋体"
            .Size = 12
            .Size = 12
            .Size = 12
        End With
        With .ParagraphFormat
            .Alignment = wdAlignParagraphLeft
            .SpaceBefore = 2.5
            .SpaceAfter = 0.5
        End With
        With .Font
            .NameAscii = "Times New Roman"
            .NameOther = "Times New Roman"
            .NameFarEast = "黑体"
            .Size = 12
        End With
        With .ParagraphFormat
            .Alignment = wdAlignParagraphLeft
            .SpaceBefore = 2.5
            .SpaceAfter = 0.5
        End With
        .BaseStyle = "正文"
        With .Font
            .NameAscii = "Times New Roman"
            .NameOther = "Times New Roman"
            .NameFarEast = "黑体"
            .Size = 12
        End With
        With .ParagraphFormat
            .Alignment = wdAlignParagraphLeft
            .SpaceBefore = 2.5
            .SpaceAfter = 0.5
        End With
        .BaseStyle = "正文"
        With .ParagraphFormat
            .IndentCharWidth Count:=0
            .FirstLineIndent = 24.094296
            .SpaceBefore = 0.5
            .LineUnitBefore = 0
            .LineUnitAfter = 0.5
            .DisableLineHeightGrid = 0
            .ReadingOrder = wdReadingOrderLtr
            .AutoAdjustRightIndent = -1
            .WidowControl = 0
            .KeepWithNext = -1
            .KeepTogether = -1
            .PageBreakBefore = 0
            .FarEastLineBreakControl = -1
            .WordWrap = -1
            .HangingPunctuation = -1
            .HalfWidthPunctuationOnTopOfLine = 0
            .AddSpaceBetweenFarEastAndAlpha = -1
            .AddSpaceBetweenFarEastAndDigit = -1
            .BaseLineAlignment = wdBaselineAlignAuto
            .Alignment = wdAlignParagraphLeft
            .SpaceBefore = 0.5
            .SpaceAfter = 2.5
        End With
        .Font.Size = 12
        .NextParagraphStyle = "正文"
    End With
End Sub
