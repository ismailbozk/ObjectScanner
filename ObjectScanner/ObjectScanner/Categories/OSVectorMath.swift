//
//  OSVectorMath.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//


extension Matrix4
{
//    simd::float4x4 Rotation(simd::float3 axis, float angle)
//    {
//    float c = cos(angle);
//    float s = sin(angle);
//    
//    simd::float4 X;
//    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
//    X.y = axis.x * axis.y * (1 - c) - axis.z*s;
//    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
//    X.w = 0.0;
//    
//    simd::float4 Y;
//    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
//    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
//    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
//    Y.w = 0.0;
//    
//    simd::float4 Z;
//    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
//    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
//    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
//    Z.w = 0.0;
//    
//    simd::float4 W;
//    W.x = 0.0;
//    W.y = 0.0;
//    W.z = 0.0;
//    W.w = 1.0;
//    
//    simd::float4x4 mat = { X, Y, Z, W };
//    return mat;
//    }
    
    static func rotation(axis axis: Vector3, angle: Scalar) -> Matrix4
    {
        let c: Scalar = cos(angle);
        let s: Scalar = sin(angle);
        
        var X = Vector4.Zero;
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
        X.y = axis.x * axis.y * (1 - c) - axis.z*s;
        X.z = axis.x * axis.z * (1 - c) + axis.y * s;
        X.w = 0.0;
    
        var Y = Vector4.Zero;
        Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
        Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
        Y.w = 0.0;

        var Z = Vector4.Zero;
        Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
        Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
        Z.w = 0.0;

        var W = Vector4.Zero;
        W.x = 0.0;
        W.y = 0.0;
        W.z = 0.0;
        W.w = 1.0;
        
        let rotationMatrix: Matrix4 =
        Matrix4(m11: X.x, m12: Y.x, m13: Z.x, m14: W.x,
                m21: X.y, m22: Y.y, m23: Z.y, m24: W.y,
                m31: X.z, m32: Y.z, m33: Z.z, m34: W.z,
                m41: X.w, m42: Y.w, m43: Z.w, m44: W.w);
        return rotationMatrix;
    }
    
    static func perspectiveProjection(aspect aspect: Float, fovy: Float, near: Float, far: Float) -> Matrix4
    {
        let yScale: Float = 1 / tan(fovy * 0.5);
        let xScale: Float = yScale / aspect;
        let zRange: Float = far - near;
        let zScale: Float = -(far + near) / zRange;
        let wzScale: Float = -2 * far * near / zRange;
        
        let P: Vector4 = Vector4(xScale, 0.0, 0.0, 0.0);
        let Q: Vector4 = Vector4(0.0, yScale, 0.0, 0.0);
        let R: Vector4 = Vector4(0.0, 0.0, zScale, -1.0);
        let S: Vector4 = Vector4(0.0, 0.0, wzScale, 0.0);
        
        let perspectiveProjection =
        Matrix4(m11: P.x, m12: Q.x, m13: R.x, m14: S.x,
                m21: P.y, m22: Q.y, m23: R.y, m24: S.y,
                m31: P.z, m32: Q.z, m33: R.z, m34: S.z,
                m41: P.w, m42: Q.w, m43: R.w, m44: S.w);
        
        return perspectiveProjection;
    }
}

extension Float
{
    static func degToRad(degree: Float) -> Float
    {
        return degree * (Float(M_PI) / 180.0);
    }
}