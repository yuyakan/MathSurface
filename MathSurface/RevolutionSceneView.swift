//
//  RevolutionSceneView.swift
//  MathSurface
//
//  SceneKit による回転体表示。Chart3D には依存しない。
//

import SwiftUI
import SceneKit

struct RevolutionSceneView: UIViewRepresentable {
    let function: LineFunction
    let axis: RevolutionAxis
    let radius: Double

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.autoenablesDefaultLighting = false
        view.backgroundColor = UIColor.systemBackground
        view.antialiasingMode = .multisampling4X
        view.scene = buildScene()
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        view.scene = buildScene()
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.systemBackground

        let mesh = buildRevolutionMesh()
        let node = SCNNode(geometry: mesh)
        scene.rootNode.addChildNode(node)

        // ライト
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        directional.light = SCNLight()
        directional.light?.type = .directional
        directional.light?.intensity = 700
        directional.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directional)

        // カメラ
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.01
        camera.zFar = 200
        cameraNode.camera = camera
        let dist = Float(radius) * 3
        cameraNode.position = SCNVector3(dist, dist * 0.7, dist)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // 座標軸（赤=x 緑=y 青=z）
        scene.rootNode.addChildNode(axisLine(direction: .x, color: .systemRed))
        scene.rootNode.addChildNode(axisLine(direction: .y, color: .systemGreen))
        scene.rootNode.addChildNode(axisLine(direction: .z, color: .systemBlue))

        return scene
    }

    private enum AxisDir { case x, y, z }

    private func axisLine(direction: AxisDir, color: UIColor) -> SCNNode {
        let length = CGFloat(radius * 2.4)
        let cyl = SCNCylinder(radius: CGFloat(radius) * 0.01, height: length)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.lightingModel = .constant
        cyl.materials = [mat]
        let node = SCNNode(geometry: cyl)
        switch direction {
        case .x: node.eulerAngles = SCNVector3(0, 0, -Float.pi / 2)
        case .y: break
        case .z: node.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        }
        return node
    }

    // MARK: - Mesh

    /// 回転体のメッシュを生成。x軸回転 / y軸回転に対応。
    /// パラメータ:
    ///   u: 軸方向（uMin..uMax の axisStep+1 分割）
    ///   θ: 回転角度（0..2π の thetaStep 分割）
    private func buildRevolutionMesh() -> SCNGeometry {
        let axisStep = 80
        let thetaStep = 64
        let uMin: Double
        let uMax: Double
        switch axis {
        case .x:
            uMin = -radius
            uMax = radius
        case .y:
            uMin = 0
            uMax = radius
        }

        var vertices: [SCNVector3] = []
        var colors: [SIMD4<Float>] = []
        vertices.reserveCapacity((axisStep + 1) * (thetaStep + 1))
        colors.reserveCapacity(vertices.capacity)

        // 値域推定（色のため）
        var minH = Double.infinity
        var maxH = -Double.infinity
        let probeStep = (uMax - uMin) / 40
        var probe = uMin
        while probe <= uMax + 1e-9 {
            let v = function.y(x: probe)
            if v.isFinite {
                if v < minH { minH = v }
                if v > maxH { maxH = v }
            }
            probe += probeStep
        }
        if !minH.isFinite || minH == maxH { minH = -1; maxH = 1 }

        for i in 0...axisStep {
            let u = uMin + (uMax - uMin) * Double(i) / Double(axisStep)
            let r = function.y(x: u)
            for j in 0...thetaStep {
                let theta = 2 * Double.pi * Double(j) / Double(thetaStep)
                let cosT = cos(theta)
                let sinT = sin(theta)
                let v: SCNVector3
                let h: Double  // 色用の高さ
                switch axis {
                case .x:
                    // (x, y, z) = (u, r·cosθ, r·sinθ)
                    v = SCNVector3(Float(u), Float(r * cosT), Float(r * sinT))
                    h = r
                case .y:
                    // (x, y, z) = (u·cosθ, r, u·sinθ)
                    v = SCNVector3(Float(u * cosT), Float(r), Float(u * sinT))
                    h = r
                }
                let isOk = v.x.isFinite && v.y.isFinite && v.z.isFinite
                vertices.append(isOk ? v : SCNVector3(0, 0, 0))
                let t = (h.isFinite && maxH != minH) ? (h - minH) / (maxH - minH) : 0.5
                colors.append(heightColor(Float(t)))
            }
        }

        var indices: [Int32] = []
        indices.reserveCapacity(axisStep * thetaStep * 6)
        let stride = thetaStep + 1
        for i in 0..<axisStep {
            for j in 0..<thetaStep {
                let a = Int32(i * stride + j)
                let b = Int32(i * stride + j + 1)
                let c = Int32((i + 1) * stride + j)
                let d = Int32((i + 1) * stride + j + 1)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD4<Float>>.stride
        )
        let indexData = indices.withUnsafeBufferPointer { Data(buffer: $0) }
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        let material = SCNMaterial()
        material.lightingModel = .blinn
        material.isDoubleSided = true
        material.specular.contents = UIColor(white: 0.3, alpha: 1)
        material.shininess = 0.4
        geometry.materials = [material]
        return geometry
    }

    private func heightColor(_ t: Float) -> SIMD4<Float> {
        let stops: [SIMD4<Float>] = [
            SIMD4(0.10, 0.30, 0.90, 1),
            SIMD4(0.10, 0.75, 0.95, 1),
            SIMD4(0.20, 0.85, 0.40, 1),
            SIMD4(0.95, 0.90, 0.20, 1),
            SIMD4(0.95, 0.55, 0.15, 1),
            SIMD4(0.90, 0.20, 0.20, 1)
        ]
        let clamped = max(0, min(1, t))
        let scaled = clamped * Float(stops.count - 1)
        let lo = Int(floor(scaled))
        let hi = min(lo + 1, stops.count - 1)
        let f = scaled - Float(lo)
        return stops[lo] * (1 - f) + stops[hi] * f
    }
}

// MARK: - Sheet

struct RevolutionSheet: View {
    let function: LineFunction
    let axis: RevolutionAxis
    let radius: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RevolutionSceneView(function: function, axis: axis, radius: radius)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("\(function.name) の\(axis.label)回転体")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}
