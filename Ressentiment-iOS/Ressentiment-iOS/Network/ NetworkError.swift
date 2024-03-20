//
//   NetworkError.swift
//  Ressentiment-iOS
//
//  Created by 이조은 on 3/10/24.
//

enum NetworkError: Int, Error, CustomStringConvertible {
    var description: String { self.errorDescription }
    case pathErr
    case requstEncodingErr
    case responseDecodingErr
    case responseErr
    case unknownErr
    case loginFailed = 400
    case internalServerErr = 500
    case notFoundErr = 404

    var errorDescription: String {
        switch self {
        case .pathErr: return "PATH_ERROR"
        case .loginFailed: return "로그인에 실패하였습니다."
        case .requstEncodingErr: return "REQUEST_ENCODING_ERROR"
        case .responseErr: return "RESPONSE_ERROR"
        case .responseDecodingErr: return "RESPONSE_DECODING_ERROR"
        case .unknownErr: return "UNKNOWN_ERROR"
        case .internalServerErr: return "500:INTERNAL_SERVER_ERROR"
        case .notFoundErr: return "404:NOT_FOUND_ERROR"
        }
    }
}
