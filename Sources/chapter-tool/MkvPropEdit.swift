import Foundation
import ExecutableDescription


struct MkvPropEdit: Executable {
  static let executableName: String = "mkvpropedit"

  var parseMode: ParseMode?

  var file: String

  var actions: [Action]

  var arguments: [String] {
    var args = [String]()
    parseMode.map { args.append(contentsOf: ["-p", $0.rawValue]) }
    args.append(file)

    actions.forEach { action in
      switch action {
      case .chapter(let filename):
        args.append(contentsOf: ["-c", filename])
      }
    }
    return args
  }

}

extension MkvPropEdit {
  enum ParseMode: String {
    case fast
    case full
  }

  enum Action {
    case chapter(filename: String)
  }
}

/*
 mkvpropedit [options] <file> <actions>

 Actions for handling properties:
 -e, --edit <selector>       Sets the Matroska file section that all following add/set/delete actions operate on (
 see below and man page for syntax)
 -a, --add <name=value>      Adds a property with the value even if such a property already exists
 -s, --set <name=value>      Sets a property to the value if it exists and add it otherwise
 -d, --delete <name>         Delete all occurrences of a property

 Actions for handling tags and chapters:
 -t, --tags <selector:filename>
 Add or replace tags in the file with the ones from 'filename' or remove them if 'fil
 ename' is empty (see below and man page for syntax)
 -c, --chapters <filename>   Add or replace chapters in the file with the ones from 'filename' or remove them if '
 filename' is empty
 --add-track-statistics-tags Calculate statistics for all tracks and add new/update existing tags for them
 --delete-track-statistics-tags
 Delete all existing track statistics tags

 Actions for handling attachments:
 --add-attachment <filename> Add the file 'filename' as a new attachment
 --replace-attachment <attachment-selector:filename>
 Replace an attachment with the file 'filename'
 --update-attachment <attachment-selector>
 Update an attachment's properties
 --delete-attachment <attachment-selector>
 Delete one or more attachments
 --attachment-name <name>    Set the name to use for the following '--add-attachment', '--replace-attachment' or '
 --update-attachment' option
 --attachment-description <description>
 Set the description to use for the following '--add-attachment', '--replace-attachme
 nt' or '--update-attachment' option
 --attachment-mime-type <mime-type>
 Set the MIME type to use for the following '--add-attachment', '--replace-attachment'
 or '--update-attachment' option
 --attachment-uid <uid>      Set the UID to use for the following '--add-attachment', '--replace-attachment' or '
 --update-attachment' option

 Other options:
 --disable-language-ietf     Do not change LanguageIETF track header elements when the 'language' property is cha
 nged.
 -v, --verbose               Increase verbosity.
 -q, --quiet                 Suppress status output.
 --ui-language <code>        Force the translations for 'code' to be used.
 --command-line-charset <charset>
 Charset for strings on the command line
 --output-charset <cset>     Output messages in this charset
 -r, --redirect-output <file>
 Redirects all messages into this file.
 --flush-on-close            Flushes all cached data to storage when closing a file opened for writing.
 --abort-on-warnings         Aborts the program after the first warning is emitted.
 @option-file.json           Reads additional command line options from the specified JSON file (see man page).
 -h, --help                  Show this help.
 -V, --version               Show version information.
 The order of the various options is not important.
 */
