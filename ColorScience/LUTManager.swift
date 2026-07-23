import CoreImage
import Foundation

func makeLUTFilter(size: Int, data: [Float]) -> CIFilter? {
    guard let filter = CIFilter(name: "CIColorCube") else { return nil }
    var cubeData = [Float]()
    for value in data {
        cubeData.append(value)
    }
    var rgbaData = [Float]()
    for i in stride(from: 0, to: cubeData.count, by: 3) {
        if i+2 < cubeData.count {
            rgbaData.append(cubeData[i])
            rgbaData.append(cubeData[i+1])
            rgbaData.append(cubeData[i+2])
            rgbaData.append(1.0)
        }
    }
    let dataObj = Data(bytes: rgbaData, count: rgbaData.count * MemoryLayout<Float>.size)
    filter.setValue(size, forKey: "inputCubeDimension")
    filter.setValue(dataObj, forKey: "inputCubeData")
    return filter
}
