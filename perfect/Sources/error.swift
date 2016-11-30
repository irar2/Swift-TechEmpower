public enum AppError: Error {
    case DBError(String, query: String)
    case DataFormatError(String)
    case OtherError(String)
}
