import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Excel Reader',
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        
        
      ),
      home: ExcelReaderPage(),
      
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExcelReaderPage extends StatefulWidget {
  
  @override
  _ExcelReaderPageState createState() => _ExcelReaderPageState();
}

class Contact {
  final String noAutoContact;
  final String typeCon;
  final String nom1CieOuFam;
  final String categorieCon;
  final String appelCon;
  final String nom2ServOuPr;
  final String nomCompletCon;
  final String nomCompletDesacCon;
  final String adresse;
  final String adresse2;
  final String ville;
  final String province;
  final String pays;
  final String codePostal;
  final String villeProvCP;
  final String importRegAvec;
  final String membreCtrl;
  final String desactive;
  final String sexe;
  final String telResidence;
  final String courrielPersonnel;
  final String orgAcronyme;
  final String telSansFrais;
  final String siteWeb;
  final String langueCommunication;
  final String creeDate;
  final String creePar;
  final String modifieDate;
  final String modifiePar;
  final String modifieNb;

  Contact({
    required this.noAutoContact,
    required this.typeCon,
    required this.nom1CieOuFam,
    required this.categorieCon,
    required this.appelCon,
    required this.nom2ServOuPr,
    required this.nomCompletCon,
    required this.nomCompletDesacCon,
    required this.adresse,
    required this.adresse2,
    required this.ville,
    required this.province,
    required this.pays,
    required this.codePostal,
    required this.villeProvCP,
    required this.importRegAvec,
    required this.membreCtrl,
    required this.desactive,
    required this.sexe,
    required this.telResidence,
    required this.courrielPersonnel,
    required this.orgAcronyme,
    required this.telSansFrais,
    required this.siteWeb,
    required this.langueCommunication,
    required this.creeDate,
    required this.creePar,
    required this.modifieDate,
    required this.modifiePar,
    required this.modifieNb,
  });

  factory Contact.fromJson(Map<String, String> json) {
    return Contact(
      noAutoContact: json['NoAutoContact'] ?? '',
      typeCon: json['TypeCon'] ?? '',
      nom1CieOuFam: json['Nom1CieOuFam'] ?? '',
      categorieCon: json['CatégorieCon'] ?? '',
      appelCon: json['AppelCon'] ?? '',
      nom2ServOuPr: json['Nom2ServOuPr'] ?? '',
      nomCompletCon: json['NomCompletCon'] ?? '',
      nomCompletDesacCon: json['NomCompletDésacCon'] ?? '',
      adresse: json['Adresse'] ?? '',
      adresse2: json['Adresse2'] ?? '',
      ville: json['Ville'] ?? '',
      province: json['Province'] ?? '',
      pays: json['Pays'] ?? '',
      codePostal: json['CodePostal'] ?? '',
      villeProvCP: json['VilleProvCP'] ?? '',
      importRegAvec: json['ImportRégAvec'] ?? '',
      membreCtrl: json['MembreCtrl'] ?? '',
      desactive: json['Désactivé'] ?? '',
      sexe: json['Sexe'] ?? '',
      telResidence: json['TélRésidence'] ?? '',
      courrielPersonnel: json['CourrielPersonnel'] ?? '',
      orgAcronyme: json['OrgAcronyme'] ?? '',
      telSansFrais: json['TélSansFrais'] ?? '',
      siteWeb: json['SiteWeb'] ?? '',
      langueCommunication: json['LangueCommunication'] ?? '',
      creeDate: json['CrééDate'] ?? '',
      creePar: json['CrééPar'] ?? '',
      modifieDate: json['ModifiéDate'] ?? '',
      modifiePar: json['ModifiéPar'] ?? '',
      modifieNb: json['ModifiéNb'] ?? '',
    );
  }
}

class _ExcelReaderPageState extends State<ExcelReaderPage> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  String selectedTypeCon = 'None';
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedData');
    if (cachedData != null) {
      try {
        List<Map<String, String>> jsonData =
            List<Map<String, String>>.from(jsonDecode(cachedData));
        List<Contact> cachedContacts =
            jsonData.map((json) => Contact.fromJson(json)).toList();
        setState(() {
          contacts = cachedContacts;
          filteredContacts = cachedContacts;
          isLoading = false;
        });
        return;
      } catch (e) {
        print('Error loading cached data: $e');
      }
    }

    ByteData data = await rootBundle.load('assets/contacts.xlsx');
    var bytes = data.buffer.asUint8List();
    var excel = Excel.decodeBytes(bytes);

    var sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null) {
      var firstRow = sheet.rows.first;
      List<Map<String, String>> jsonData = [];
      for (var row in sheet.rows.skip(1)) {
        Map<String, String> json = {};
        for (int i = 0; i < firstRow.length; i++) {
          json[firstRow[i]?.value.toString() ?? ''] = row[i]?.value.toString() ?? '';
        }
        jsonData.add(json);
      }

      List<Contact> newContacts =
          jsonData.map((json) => Contact.fromJson(json)).toList();
      await prefs.setString('cachedData', jsonEncode(jsonData));
      setState(() {
        contacts = newContacts;
        filteredContacts = newContacts;
        isLoading = false;
      });
    }
  }

  void filterContacts() {
    setState(() {
      if (selectedTypeCon == 'None' && searchQuery.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((contact) {
          bool matchesTypeCon = selectedTypeCon == 'None' ||
              contact.typeCon.toLowerCase() == selectedTypeCon.toLowerCase();
          bool matchesSearchQuery = contact.noAutoContact
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
          return matchesTypeCon && matchesSearchQuery;
        }).toList();
      }
    });
  }

   void showOverlay(Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Contact Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NoAutoContact: ${contact.noAutoContact}'),
                Text('TypeCon: ${contact.typeCon}'),
                Text('Nom1CieOuFam: ${contact.nom1CieOuFam}'),
                Text('CatégorieCon: ${contact.categorieCon}'),
                Text('AppelCon: ${contact.appelCon}'),
                Text('Nom2ServOuPr: ${contact.nom2ServOuPr}'),
                Text('NomCompletCon: ${contact.nomCompletCon}'),
                Text('NomCompletDésacCon: ${contact.nomCompletDesacCon}'),
                Text('Adresse: ${contact.adresse}'),
                Text('Adresse2: ${contact.adresse2}'),
                Text('Ville: ${contact.ville}'),
Text('Province: ${contact.province}'),
Text('Pays: ${contact.pays}'),
Text('CodePostal: ${contact.codePostal}'),
Text('VilleProvCP: ${contact.villeProvCP}'),
Text('ImportRégAvec: ${contact.importRegAvec}'),
Text('MembreCtrl: ${contact.membreCtrl}'),
Text('Désactivé: ${contact.desactive}'),
Text('Sexe: ${contact.sexe}'),
Text('TélRésidence: ${contact.telResidence}'),
Text('CourrielPersonnel: ${contact.courrielPersonnel}'),
Text('OrgAcronyme: ${contact.orgAcronyme}'),
Text('TélSansFrais: ${contact.telSansFrais}'),
Text('SiteWeb: ${contact.siteWeb}'),
Text('LangueCommunication: ${contact.langueCommunication}'),
Text('CrééDate: ${contact.creeDate}'),
Text('CrééPar: ${contact.creePar}'),
Text('ModifiéDate: ${contact.modifieDate}'),
Text('ModifiéPar: ${contact.modifiePar}'),
Text('ModifiéNb: ${contact.modifieNb}'),
],
),
),
actions: <Widget>[
TextButton(
onPressed: () {
Navigator.of(context).pop();
},
child: Text('Close'),
),
],
);
},
);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(110, 252, 224, 224),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(0, 235, 247, 236),
        title: Text('Flutter Excel Reader'),
        
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by NoAutoContact',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterContacts();
                      });
                    },
                  ),
                ),
                //dropdown here
                /*Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedTypeCon,
                    items: ['None', 'Type1', 'Type2'] // Add your types here
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTypeCon = value ?? 'None';
                        filterContacts();
                      });
                    },
                    isExpanded: true,
                  ),
                ),*/
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      Contact contact = filteredContacts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text('NoAutoCon: ${contact.noAutoContact}'),
                          subtitle: Text('TypeCon: ${contact.typeCon}'),
                          trailing: Text(contact.nom1CieOuFam),
                          onTap: () {
                            showOverlay(contact);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
