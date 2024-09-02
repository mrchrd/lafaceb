function onFormSubmit(e) {
  var showItemTitle = "Émission";
  var artistItemTitle = "Artiste";
  var trackFileItemTitle = "Fichier";

  var form = FormApp.openById(e.source.getId());
  var items = form.getItems();
  var showItem = items.filter(item => item.getTitle() == showItemTitle)[0];
  var artistItem = items.filter(item => item.getTitle() == artistItemTitle)[0];
  var trackFileItem = items.filter(item => item.getType() == 'FILE_UPLOAD' && item.getTitle() == trackFileItemTitle)[0];

  var resp = e.response;
  var show = resp.getResponseForItem(showItem).getResponse();
  var artist = resp.getResponseForItem(artistItem).getResponse();
  var trackFileId = resp.getResponseForItem(trackFileItem).getResponse();

  Logger.log('%s: %s', showItem.getTitle(), show);
  Logger.log('%s: %s', artistItem.getTitle(), artist);
  
  if (show && artist && trackFileId) {
    var trackFile = DriveApp.getFileById(trackFileId);
    var trackFileOldName = trackFile.getName();
    var trackFileExt = extractFileExtension(trackFileOldName);
    var trackFileNewName = show + ' #XX - XX - ' + artist + '.' + trackFileExt;
    trackFile.setName(trackFileNewName);
    var trackFileName = trackFile.getName();
  }

  Logger.log('%s: %s (anciennement %s)', trackFileItem.getTitle(), trackFileName, trackFileOldName);
}

function extractFileExtension(filename) {
  var dotIndex = filename.lastIndexOf('.');

  if (dotIndex > 0) {
    return filename.substring(dotIndex + 1);
  } else {
    return '';
  }
}
