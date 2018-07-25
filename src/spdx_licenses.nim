## A library to retrieve the list of commonly used licenses from the SPDX License List.

import asyncdispatch, tables, httpclient, json

const
  defaultLicenseListSource = "https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json"
  licenseDetailsBaseSource = "http://spdx.org/licenses/"

type
  License* = object
    ## An individual license.
    reference*: string
    isDeprecatedLicenseId*: bool
    detailsUrl*: string
    referenceNumber*: string
    name*: string
    licenseId*: string
    seeAlso*: seq[string]
    isOsiApproved*: bool

  LicenseDetails* = object
    ## Details for an individual license.
    licenseText*: string
    standardLicenseTemplate*: string

  LicenseList* = TableRef[string, License]
    ## A list of licenses, keyed by license ID for easy lookup by ID.

template parseSeeAlso(dest: var seq[string], obj: JsonNode) =
  doAssert obj.kind == JArray

  dest.setLen(len(obj))

  for entry in obj.items():
    dest.add(entry.getStr())

template parseLicense(table: LicenseList, obj: JsonNode) =
  doAssert obj.kind == JObject

  var lic = License(
    reference: obj["reference"].getStr(),
    isDeprecatedLicenseId: obj["isDeprecatedLicenseId"].getBool(),
    detailsUrl: obj["detailsUrl"].getStr(),
    referenceNumber: obj["referenceNumber"].getStr(),
    name: obj["name"].getStr(),
    licenseId: obj["licenseId"].getStr(),
    seeAlso: @[],
    isOsiApproved: obj["isOsiApproved"].getBool()
  )

  parseSeeAlso(lic.seeAlso, obj["seeAlso"])

  table[lic.licenseId] = lic

proc getLicenseList*(httpClient: HttpClient | AsyncHttpClient,
                     licenseListSource = defaultLicenseListSource): Future[LicenseList] {.multisync.} =
    ## Get the SPDX list of commonly used licenses using the given HTTP client.
    ## You can optionally specify an alternative URL to the license list source.
    let content = await httpClient.getContent(licenseListSource)

    let jsonNode = parseJson(content)
    doAssert jsonNode.kind == JObject
    doAssert jsonNode.hasKey("licenses")
    doAssert jsonNode["licenses"].kind == JArray

    let licensesArray = jsonNode["licenses"]

    result = newTable[string, License](tables.rightSize(len(licensesArray)))

    for license in licensesArray.items():
      parseLicense(result, license)

proc getLicenseList*(licenseListSource = defaultLicenseListSource):
  LicenseList =
  ## Get the SPDX list of commonly used licenses using a default HTTP client.
  let httpClient = newHttpClient()
  result = getLicenseList(httpClient, licenseListSource)

proc getLicenseListAsync*(licenseListSource = defaultLicenseListSource):
  Future[LicenseList] =
  ## Asynchronously get the SPDX list of commonly used licenses using a default HTTP client.
  let httpClient = newAsyncHttpClient()
  result = getLicenseList(httpClient, licenseListSource)

proc details*(license: License, httpClient: HttpClient | AsyncHttpClient):
  Future[LicenseDetails] {.multisync.} =
  ## Get the details for a license using the given HTTP client.
  let content = await httpClient.getContent(license.detailsUrl)

  let jsonNode = parseJson(content)
  doAssert(jsonNode.kind == JObject)

  result = LicenseDetails(
    licenseText: jsonNode["licenseText"].getStr(),
    standardLicenseTemplate: jsonNode["standardLicenseTemplate"].getStr()
  )

proc details*(license: License): LicenseDetails =
  ## Get the details for a license using a default HTTP client.
  let httpClient = newHttpClient()
  result = details(license, httpClient)

proc detailsAsync*(license: License): Future[LicenseDetails] =
  ## Asynchronously get the details for a license using a default HTTP client.
  let httpClient = newAsyncHttpClient()
  result = details(license, httpClient)

proc getLicenseText*(licenseId: string,
                                 httpClient: HttpClient | AsyncHttpClient):
                                 Future[string] {.multisync.} =
  ## Get the license text for the given license ID using the given HTTP client.
  let url = licenseDetailsBaseSource & licenseId & ".json"
  let content = await httpClient.getContent(url)

  let jsonNode = parseJson(content)
  doAssert(jsonNode.kind == JObject)

  result = jsonNode["licenseText"].getStr()

proc getLicenseText*(licenseId: string): string =
  ## Get the license text for the given license ID using a default HTTP client.
  let httpClient = newHttpClient()
  result = getLicenseText(licenseId, httpClient)

proc getLicenseTextAsync*(licenseId: string): Future[string] =
  ## Asynchronously get the license text for the given license ID using a default HTTP client.
  let httpClient = newAsyncHttpClient()
  result = getLicenseText(licenseId, httpClient)

when isMainModule:
  let licenses = getLicenseList()

  assert len(licenses) > 0

  echo "Found licenses: "

  for lic in licenses.keys:
    echo "- ", lic

  stdout.write("Select a license to see the full license text: ")
  let selected = stdin.readLine()

  let selectedLicense = licenses[selected]

  let licenseDetails = selectedLicense.details()

  echo licenseDetails.licenseText
