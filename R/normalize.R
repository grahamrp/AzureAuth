#' Normalize GUID and tenant values
#'
#' These functions are used by `get_azure_token` to recognise and properly format tenant and app IDs. `is_guid` can also be used generically for identifying GUIDs/UUIDs in any context.
#'
#' @param tenant For `normalize_tenant`, a string containing an Azure Active Directory tenant. This can be a name ("myaadtenant"), a fully qualified domain name ("myaadtenant.onmicrosoft.com" or "mycompanyname.com"), or a valid GUID.
#' @param x For `is_guid`, a character string; for `normalize_guid`, a string containing a _validly formatted_ GUID.
#'
#' @details
#' A tenant can be identified either by a GUID, or its name, or a fully-qualified domain name (FQDN). The rules for normalizing a tenant are:
#' 1. If `tenant` is recognised as a valid GUID, return its canonically formatted value
#' 2. Otherwise, if it is a FQDN, return it
#' 3. Otherwise, if it is not the string "common", append ".onmicrosoft.com" to it
#' 4. Otherwise, return the value of `tenant`
#'
#' These functions are vectorised. See the link below for the GUID formats they accept.
#'
#' @return
#' For `is_guid`, a logical vector indicating which values of `x` are validly formatted GUIDs.
#'
#' For `normalize_guid`, a vector of GUIDs in canonical format. If any values of `x` are not recognised as GUIDs, it throws an error.
#'
#' For `normalize_tenant`, the normalized tenant IDs or names.
#'
#' @seealso
#' [get_azure_token]
#'
#' [Parsing rules for GUIDs in .NET](https://docs.microsoft.com/en-us/dotnet/api/system.guid.parse). `is_guid` and `normalize_guid` recognise the "N", "D", "B" and "P" formats.
#'
#' @examples
#'
#' is_guid("72f988bf-86f1-41af-91ab-2d7cd011db47")    # TRUE
#' is_guid("{72f988bf-86f1-41af-91ab-2d7cd011db47}")  # TRUE
#' is_guid("72f988bf-86f1-41af-91ab-2d7cd011db47}")   # FALSE (unmatched brace)
#' is_guid("microsoft")                               # FALSE
#'
#' # all of these return the same value
#' normalize_guid("72f988bf-86f1-41af-91ab-2d7cd011db47")
#' normalize_guid("{72f988bf-86f1-41af-91ab-2d7cd011db47}")
#' normalize_guid("(72f988bf-86f1-41af-91ab-2d7cd011db47)")
#' normalize_guid("72f988bf86f141af91ab2d7cd011db47")
#'
#' normalize_tenant("microsoft")     # returns 'microsoft.onmicrosoft.com'
#' normalize_tenant("microsoft.com") # returns 'microsoft.com'
#' normalize_tenant("72f988bf-86f1-41af-91ab-2d7cd011db47") # returns the GUID
#'
#' # vector arguments are accepted
#' ids <- c("72f988bf-86f1-41af-91ab-2d7cd011db47", "72f988bf86f141af91ab2d7cd011db47")
#' is_guid(ids)
#' normalize_guid(ids)
#' normalize_tenant(c("microsoft", ids))
#'
#' @export
#' @rdname guid
normalize_tenant <- function(tenant)
{
    if(!is.character(tenant))
        stop("Tenant must be a character string", call.=FALSE)

    tenant <- tolower(tenant)

    # check if supplied a guid; if not, check if a fqdn;
    # if not, check if 'common'; if not, append '.onmicrosoft.com'
    guid <- is_guid(tenant)
    tenant[guid] <- normalize_guid(tenant[guid])

    name <- !guid & (tenant != "common") & !grepl(".", tenant, fixed=TRUE)
    tenant[name] <- paste0(tenant[name], ".onmicrosoft.com")

    tenant
}


#' @export
#' @rdname guid
normalize_guid <- function(x)
{
    if(!all(is_guid(x)))
        stop("Not a GUID", call.=FALSE)

    x <- sub("^[({]?([-0-9a-f]+)[})]$", "\\1", x)
    x <- gsub("-", "", x)
    return(paste(
        substr(x, 1, 8),
        substr(x, 9, 12),
        substr(x, 13, 16),
        substr(x, 17, 20),
        substr(x, 21, 32), sep="-"))
}


#' @export
#' @rdname guid
is_guid <- function(x)
{
    if(!is.character(x))
        return(FALSE)
    x <- tolower(x)

    grepl("^[0-9a-f]{32}$", x) |
    grepl("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x) |
    grepl("^\\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}$", x) |
    grepl("^\\([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\)$", x)
}


normalize_aad_version <- function(v)
{
    if(v == "v1.0")
        v <- 1
    else if(v == "v2.0")
        v <- 2
    if(!(is.numeric(v) && v %in% c(1, 2)))
        stop("Invalid AAD version")
    v
}

