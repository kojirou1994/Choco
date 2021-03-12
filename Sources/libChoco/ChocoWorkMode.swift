public enum ChocoWorkMode: String, CaseIterable, Codable {
  // mux and remux all mpls
  case movieBDMV
  // only mux bdmv mpls
  case directBDMV
  // split all mpls
  case splitBDMV
  // map all files to output dir's same dir structure
  case directory
  // input is *.mkv or something else
  case file
}
