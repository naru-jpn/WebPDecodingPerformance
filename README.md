# WebPDecodingPerformance
Investigate decoding animated WebP on iOS devices.

## Overview
Performance for decoding animated WebP may have gotten worse since iOS 18. The processing time for decoding continuous WebP frames is extremely slow on iOS 17, and in addition, CPU usage has become extremely high since iOS 18. This sample project reproduces that.

## Detail
CPU usage when displaying continuous WebP images on iOS 17 is around 50-60%. However, on iOS 18, CPU usage reaches 100%, causing the application to freeze.

This problem is probably caused by the decoding process of WebP images on iOS. Animated WebP images are converted to UIImage as shown below.

```
// Data
let data = try! Data(contentsOf: URL(fileURLWithPath: path))

// CFData → CGImageSource
let source = CGImageSourceCreateWithData(data as CFData, nil)!

// CGImageSource → [CGImage]
let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil)! // for all `index`

// [CGImage] → [UIImage]
let uiImage = UIImage(cgImage: cgImage) // for all `index`

// [UIImage] → [SwiftUI.Image] 
let image = SwiftUI.Image(uiImage: uiImage) // for all `index`
```

The process of converting WebP resource data to any data format described above is not slow. However, converting image formats or displaying images is extremely slow. All example code below is slow when processing continuous `index` values.

```
// 1
uiImages[index].pngData() 

// 2
uiImages[index].jpegData(compressionQuality: 1.0)

// 3
uiImages[index].jpegData(compressionQuality: 0.1)

// 4
// Type of `images` is [SwiftUI.Image]
var body: some View {
  images[index]
}
```

I believe that the decoding process required to convert or display WebP-formatted images is computationally expensive on iOS.

## Reference

- The video files were downloaded from [this site](https://video-ac.com/video/746).
