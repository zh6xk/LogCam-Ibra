import Foundation

func parseCubeLUT(from url: URL) throws -> (size: Int, data: [Float]) {
    let content = try String(contentsOf: url, encoding: .utf8)
    var lutSize = 0
    var values: [Float] = []

    for line in content.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("LUT_3D_SIZE") {
            lutSize = Int(trimmed.split(separator: " ").last ?? "0") ?? 0
        } else if !trimmed.isEmpty && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("TITLE") && !trimmed.hasPrefix("DOMAIN") {
            let comps = trimmed.split(separator: " ").compactMap { Float($0) }
            if comps.count == 3 { values.append(contentsOf: comps) }
        }
    }
    return (lutSize, values)
}
