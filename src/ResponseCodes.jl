module ResponseCodes

using HTTP

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#information_responses
abstract type ResponseCode end


# Internal code to make generating the open-api easier
struct Default <: ResponseCode end
Base.Int(::Default) = 200

# Information codes
struct Continue <: ResponseCode end
Base.Int(::Continue) = 100

struct SwitchingProtocols <: ResponseCode end
Base.Int(::SwitchingProtocols) = 101

struct Processing <: ResponseCode end
Base.Int(::Processing) = 102

struct EarlyHints <: ResponseCode end
Base.Int(::EarlyHints) = 103


# Sucess codes
struct Ok <: ResponseCode end
Base.Int(::Ok) = 200

struct Created <: ResponseCode end
Base.Int(::Created) = 201

struct Accepted <: ResponseCode end
Base.Int(::Accepted) = 202

struct NonAuthoritativeInformation <: ResponseCode end
Base.Int(::NonAuthoritativeInformation) = 203

struct NoContent <: ResponseCode end
Base.Int(::NoContent) = 204

struct ResetContent <: ResponseCode end
Base.Int(::ResetContent) = 205

struct PartialContent <: ResponseCode end
Base.Int(::PartialContent) = 207

# Redireciton Codes

struct MultipleChoice <: ResponseCode end
Base.Int(::MultipleChoice) = 300

struct MovePermanetly <: ResponseCode end
Base.Int(::MovePermanetly) = 301

struct Found <: ResponseCode end
Base.Int(::Found) = 302

struct SeeOther <: ResponseCode end
Base.Int(::SeeOther) = 303

struct NotModified <: ResponseCode end
Base.Int(::NotModified) = 304

struct TemporaryRedirect <: ResponseCode end
Base.Int(::TemporaryRedirect) = 307

struct PermanentRedirect <: ResponseCode end
Base.Int(::PermanentRedirect) = 308

# Client Error codes

struct BadRequest <: ResponseCode end
Base.Int(::BadRequest) = 400

struct Unauthorized <: ResponseCode end
Base.Int(::Unauthorized) = 401

struct PaymentRequired <: ResponseCode end
Base.Int(::PaymentRequired) = 402

struct Forbidden <: ResponseCode end
Base.Int(::Forbidden) = 403

struct NotFound <: ResponseCode end
Base.Int(::NotFound) = 404

struct MethodNotAllowed <: ResponseCode end
Base.Int(::MethodNotAllowed) = 405

struct NotAcceptable <: ResponseCode end
Base.Int(::NotAcceptable) = 406

struct ProxyAuthenticationRequired <: ResponseCode end
Base.Int(::ProxyAuthenticationRequired) = 407

struct RequestTimeout <: ResponseCode end
Base.Int(::RequestTimeout) = 408

struct Conflict <: ResponseCode end
Base.Int(::Conflict) = 409

struct Gone <: ResponseCode end
Base.Int(::Gone) = 410

struct LengthRequired <: ResponseCode end
Base.Int(::LengthRequired) = 411

struct PreconditionFailed <: ResponseCode end
Base.Int(::PreconditionFailed) = 412

struct PayloadTooLarge <: ResponseCode end
Base.Int(::PayloadTooLarge) = 413

struct URITooLong <: ResponseCode end
Base.Int(::URITooLong) = 414

struct UnsupportedMediatype <: ResponseCode end
Base.Int(::UnsupportedMediatype) = 415

# Server error codes

struct InternalServerError <: ResponseCode end
Base.Int(::InternalServerError) = 500

struct NotImplemented <: ResponseCode end
Base.Int(::NotImplemented) = 501

struct BadGateway <: ResponseCode end
Base.Int(::BadGateway) = 502

struct ServiceUnavailable <: ResponseCode end
Base.Int(::ServiceUnavailable) = 503

struct GatewayTimeout <: ResponseCode end
Base.Int(::GatewayTimeout) = 504


HTTP.statustext(code::T) where T <: ResponseCode =  HTTP.statustext(Int(code))

end