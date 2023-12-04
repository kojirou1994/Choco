import Foundation

public enum ChocoError: Error {
  case errorReadingFile
  case noPlaylists
  case sameFilename
  case outputExist
  case noOutputFile(URL)
  case openDirectory(URL)
  case copyFile(Error)
  case directoryInputButNotRecursive
  case inputNotExists
  case bdmvInputNotDirectory
  case mkvmergeIdentification(Error)
  case mediainfo(Error)
  case ffmpegExtractAudio(Error)
  case validateFlacMD5(Error)
  case mkvmergeMux(Error)
  case parseBDMV(Error)
  case terminated
  case noCropInfo
  case nonProgTrackInProgOnlyMode
  case createDirectory(URL)
  case subTask(Error)

  case invalidFPS(String)
}
