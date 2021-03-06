var logger = require('./logger.js');

var getDBPromis = function(){
    var dbconfig = require('./dbconfig.js');
    var credentials = dbconfig.getCredentials();
    logger.consoleInfo('Setze die Datenbank-URL auf ' + credentials);
    var pgp = require('pg-promise')();
    var db = pgp(credentials);
    return db;
};

var db = getDBPromis();

//1. Einfache SELECT-Abfragen
//============================
//1.1 Versicherung
//-----------------
exports.selectVersicherungOf = function(personID, onSuccess, onError){
    // var query = queries.selectVersicherungOf;
    db.func('getversicherungpersonbyuid',[personID]).then(onSuccess).catch(onError);
};

exports.selectVersicherung = function(versicherungID, onSuccess, onError){
    //var query = queries.selectVersicherung;
    db.func('getversicherungpersonbyvid',[versicherungID]).then(onSuccess).catch(onError);
};

exports.selectBewertungen = function(versicherungID, onSuccess, onError){
    db.func('getversicherungsbewertungenbyvid',[versicherungID]).then(onSuccess).catch(onError);
};

// Filtern und sortieren von Versicherungen
exports.filterVersicherung = function(kategorie, orderby, asc_desc, limit, skip, onSuccess, onError){
    db.func('filterversicherung',[kategorie, orderby,(asc_desc?"ASC":"DESC"), limit, skip]).then(onSuccess).catch(onError);
};

// Filtern und sortieren von Versicherungen
exports.filterVersicherungCount = function(kategorie, orderby, asc_desc, limit, skip, onSuccess, onError){
    db.func('filterversicherungcount',[kategorie, orderby,(asc_desc?"ASC":"DESC"), limit, skip]).then(onSuccess).catch(onError);
};

// Sortieren von Versicherungen
exports.orderVersicherung = function(orderby, asc_desc, limit, skip, onSuccess, onError){
    db.func('orderversicherung',[orderby, (asc_desc?"ASC":"DESC"), limit, skip]).then(onSuccess).catch(onError);
};
//
//1.2 Kategorien der Versicherungen
//---------------------------------
exports.selectKategorien = function(onSuccess, onError){
    db.func('getkategorien').then(onSuccess).catch(onError);
};

//
//1.3 Investition
//-----------------
exports.selectInvestitionOf = function(personID, onSuccess, onError){
    // var query = queries.selectInvestitionOf;
    db.func('getinvestitionkomplettbyuid',[personID]).then(onSuccess).catch(onError);
};

exports.selectInvestitionen = function(versicherungID, onSuccess, onError){
    // var query = queries.selectInvestitionen;
    db.func('getinvestitionkomplettbyvid',[versicherungID]).then(onSuccess).catch(onError);
};

exports.selectInvestition = function(investitionID, onSuccess, onError){
    // var query = queries.selectInvestition
    db.func('getinvestitionkomplettbyiid',[investitionID]).then(onSuccess).catch(onError);
};

//
//1.4 Investoren/Investitionssumme von Versicherung
//--------------------------------------------------
exports.selectInvestorenVonVersicherung = function(versicherungID, onSuccess, onError){
    db.func('getinvestorenbyvid',versicherungID).then(onSuccess).catch(onError);
};

exports.selectInvestitionsSumVonVersicherung = function(versicherungID, onSuccess, onError){
    db.func('getinvestitionssummebyvid',[versicherungID]).then(onSuccess).catch(onError);
};

//
// 1.5 Schadensfall
//------------------
exports.getSchadensfallByID = function(id, onSuccess, onError){
    db.func('getschadensfallbysid',[id]).then(onSuccess).catch(onError);
};

exports.getSchadensfaelleByVersicherung = function(versicherungID, onSuccess, onError){
    db.func('getschadensfallbyvid',[versicherungID]).then(onSuccess).catch(onError);
};

//
// 1.6 Profil
//------------
exports.getProfilByID = function(personID, onSuccess, onError){
    db.func('getprofilkomplettbyuid',[personID]).then(onSuccess).catch(onError);
};
exports.getPublicProfilByID = function(personID, onSuccess, onError){
    db.func('getprofilpublicbyuid',[personID]).then(onSuccess).catch(onError);
};
//
// 1.7 Kommentare einer Versicherung
//-----------------------------------
exports.getKommentareByVID = function(versicherungID, onSuccess, onError){
    db.func('getkommentarebyvid',[versicherungID]).then(onSuccess).catch(onError);
};

//
// 1.8 Kommentare nach Kommentar ID
//
exports.getKommentarByKID = function(kommentarID, onSuccess, onError){
    db.func('getkommentarbykid',[kommentarID]).then(onSuccess).catch(onError);
};

//
//2. Einfache INSERT-Anweisungen
//===============================
//2.1 Versicherung
//-----------------
exports.erstelleVersicherung = function(personID, name, versicherungshoehe, beitrag, beschreibung, kategorie, onSuccess, onError){
    db.func('createversicherung', [personID, name, versicherungshoehe, beitrag, beschreibung, kategorie]).then(onSuccess).catch(onError);
};

//
//2.2 Zahlung
//------------
exports.insertZahlung = function(versicherungID, personID, betrag, onSuccess, onError){
    db.func('executezahlung', [versicherungID,personID,betrag]).then(onSuccess).catch(onError);
};

//
//2.3 Schadensfall
//---------------
exports.erstelleSchadensfall = function(versicherungID, bezeichnung, beschreibung, schadenshoehe, onSuccess, onError){
    db.func('createschadensfall', [versicherungID,bezeichnung,beschreibung,schadenshoehe]).then(onSuccess).catch(onError);
};

//
//2.4 Kommentar
//------------
exports.erstelleKommentar = function(versicherungID, text, personID, onSuccess, onError){
    db.func('createkommentar', [versicherungID, text, personID]).then(onSuccess).catch(onError);
};

//
//3. Einfache UPDATE-Anfragen
//==========================================


//3.1 Bewertung einer Investition

exports.getinvestitionbewertung = function(investitionID, onSuccess, onError){
    db.func('getinvestitionbewertung', [investitionID]).then(onSuccess).catch(onError);
};
exports.setinvestitionbewertung = function(investitionID, bewertung, onSuccess, onError){
    db.func('setinvestitionbewertung', [investitionID, bewertung]).then(onSuccess).catch(onError);
};


//2.2 Kuendigungen
//-----------------
exports.updateVersicherungGekuendigt = function(onSuccess, onError){
    db.func('finalizeversicherungskuendigung').then(onSuccess).catch(onError);
};

exports.investitionKuendigungEinreichen = function(investitionID, onSuccess, onError){
    db.func('submitinvestitionskuendigung', investitionID).then(onSuccess).catch(onError);
};

//
//2.2 Schadensfall
//-----------------
exports.updateSchadensfall = function(schadensfallID, bezeichnung, beschreibung, schadenshoehe, onSuccess, onError){
    db.func('updateschadensfall', [schadensfallID,bezeichnung,beschreibung,schadenshoehe]).then(onSuccess).catch(onError);
};

//
//2.2.1 Schadensfall ausgezahlt = true
exports.finalizeSchadensfall = function(onSuccess, onError){
    db.func('finalizeschadensfall').then(onSuccess).catch(onError);
};

//
//2.2.2 Schaden auszahlen
exports.paySchadensfaelle = function(onSuccess, onError){
    db.func('payschadensfaelle').then(onSuccess).catch(onError);
};

//
//2.2.3 Schaden von den Investitionshoehen abziehen
exports.reduceInvestitionenWegenSchaden = function(onSuccess, onError){
    db.func('reduceinvestitionenwegenschaden').then(onSuccess).catch(onError);
};

//
//2.3 Versicherung
//-----------------
exports.updateVersicherung = function(versicherungID, name, beschreibung, kategorie, onSuccess, onError){
    db.func('updateversicherung', [versicherungID,name,beschreibung,kategorie]).then(onSuccess).catch(onError);
};

//
//2.4 Investition
//-----------------
exports.updateInvestition = function(investitionID, investitionshoehe, onSuccess, onError){
    db.func('updateinvestition', [investitionID,investitionshoehe]).then(onSuccess).catch(onError);
};

//
//3.5 Profil bearbeiten
//-----------------
exports.changeProfil = function(personID, name, prename, email, iban, bic, bankinstitut, birthday, onSuccess, onError){
    db.func('updateprofil', [personID, name, prename, email, iban, bic, bankinstitut, birthday]).then(onSuccess).catch(onError);
};

//
//4. Komplexe / Zusammengesetzte Abfragen
//==========================================
//4.1 Investition und Investitionszahlung eintragen
//-------------------------------------------------
exports.erstelleInvestition = function(versicherungID, personID, betrag, onSuccess, onError){
    db.func('createinvestition',[versicherungID, personID, betrag]).then(onSuccess).catch(onError);
};

//
//4.2 Versicherung kuendigung einreichen und dazugehoerige Investition kuendigung einreichen
//---------------------------------------------------------------------------------------------
exports.versicherungKuendigungEinreichen = function(versicherungID, onSuccess, onError){
    db.func('submitversicherungskuendigung', versicherungID).then(onSuccess).catch(onError);
};

//
//4.3 Investition zurueckzahlen und Investition tatsaechlich kuendigen
//---------------------------------------------------------------------
exports.investitionKuendigen = function(onSuccess, onError){
    db.func('finalizeinvestitionskuendigung').then(onSuccess).catch(onError);
};

//
//4.4 Sonstige ;-) //TODO: Kommentare einfuegen
//
exports.getPaymentrelevantInvestitions = function(onSuccess, onError){
    db.func('getzahlungsrelevanteinvestitionen').then(onSuccess).catch(onError);
};

exports.selectActiveVersicherungAndCalculateBeitrag = function(onSuccess, onError){
    db.func('getversicherungundbeitraege').then(onSuccess).catch(onError);
};
