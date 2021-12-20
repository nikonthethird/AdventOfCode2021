Option Strict On
Imports System.IO
Imports System.Text

Module Program
    Function ReadInput() As (EnhancementAlgorithm As Byte(), Image As Byte(,), Filler As Byte)
        Dim lines = File.ReadAllLines("input.txt")
        Dim enhancementAlgorithm =
            From item In lines(0).ToCharArray()
            Select Convert.ToByte(item = "#"c)
        Dim image(lines(2).Length - 1, lines.Length - 3) As Byte
        For y = 0 To image.GetLength(0) - 1
            For x = 0 To image.GetLength(1) - 1
                image(y, x) = Convert.ToByte(lines(y + 2)(x) = "#"c)
            Next
        Next
        ReadInput = (enhancementAlgorithm.ToArray(), image, Convert.ToByte(False))
    End Function

    Function IndexForPixel(y As Integer, x As Integer, image As Byte(,), filler As Byte) As Integer
        Dim binaryIndex = New StringBuilder()
        For dy = -1 To 1
            For dx = -1 To 1
                If y + dy < 0 Or y + dy >= image.GetLength(0) Or x + dx < 0 Or x + dx >= image.GetLength(1) Then
                    binaryIndex.Append(filler)
                Else
                    binaryIndex.Append(image(y + dy, x + dx))
                End If
            Next
        Next
        IndexForPixel = Convert.ToInt32(binaryIndex.ToString(), 2)
    End Function

    Function EnhanceOnce(image As Byte(,), filler As Byte, enhancementAlgorithm As Byte()) As (Image As Byte(,), Filler As Byte)
        Dim newImage(image.GetLength(0) + 1, image.GetLength(1) + 1) As Byte
        For y = -1 To image.GetLength(0)
            For x = -1 To image.GetLength(1)
                Dim index = IndexForPixel(y, x, image, filler)
                newImage(y + 1, x + 1) = enhancementAlgorithm(index)
            Next
        Next
        Dim newFiller = enhancementAlgorithm(IndexForPixel(-3, -3, image, filler))
        EnhanceOnce = (newImage, newFiller)
    End Function

    Function Enhance(image As Byte(,), filler As Byte, enhancementAlgorithm As Byte(), times As Integer) As (Image As Byte(,), Filler As Byte)
        If times = 0 Then
            Enhance = (image, filler)
        Else
            Dim enhancedData = EnhanceOnce(image, filler, enhancementAlgorithm)
            Enhance = Enhance(enhancedData.Image, enhancedData.Filler, enhancementAlgorithm, times - 1)
        End If
    End Function

    Function CountPixels(image As Byte(,)) As Integer
        Dim count = 0
        For y = 0 To image.GetLength(0) - 1
            For x = 0 To image.GetLength(1) - 1
                If Convert.ToBoolean(image(y, x)) Then
                    count += 1
                End If
            Next
        Next
        CountPixels = count
    End Function

    Sub Main()
        Dim inputData = ReadInput()
        Dim enhancedTwiceData = Enhance(inputData.Image, inputData.Filler, inputData.EnhancementAlgorithm, 2)
        Console.WriteLine($"2021-12-20 Part 1: {CountPixels(enhancedTwiceData.Image)}")
        Dim enhancedFiftyTimesData = Enhance(enhancedTwiceData.Image, enhancedTwiceData.Filler, inputData.EnhancementAlgorithm, 48)
        Console.WriteLine($"2021-12-20 Part 2: {CountPixels(enhancedFiftyTimesData.Image)}")
    End Sub
End Module
