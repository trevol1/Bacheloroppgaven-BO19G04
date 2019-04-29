import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_html/flutter_html.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:splashscreen/splashscreen.dart';

// SLUGS (også kalt "permanent lenke" i wordpress) som brukes for kategorier og sider
const SLUG_PROGRAMS = "app_dager";
const SLUG_ALLSANG = "artister-allsang-pa-grensen";
const SLUG_ADKOMST_FOT = "app_fot";
const SLUG_ADKOMST_TOG = "app_tog";
const SLUG_ADKOMST_BUSS = "app_buss";
const SLUG_ADKOMST_BIL = "app_bil";
const SLUG_REKLAME = "app_reklame";

// Nett-URL vi kommuniserer med
//const API_URL = "https://allsangpagrensen.no/api/"; // Live Allsang på Grensen side
const API_URL = "http://10.0.2.2/wordpress/api/"; // Testing gjennom Android Studio med lokal Wordpress
//const API_URL = "https://itstud.hiof.no/~vegardbe/wordpress/api/"; // Testing på live Wordpress

const WP_URL = "https://www.allsangpagrensen.no/"; // For innebygd innhold uten en adresse
const LOGO_URL = 'https://www.allsangpagrensen.no/wp-content/uploads/2014/04/allsanglogo-600.png'; // Hovedlogo

const ARENA_URL = "https://www.allsangpagrensen.no/wp-content/uploads/2018/06/arenakart.png"; // Arenakart under "Kart"-fanen

const TICKETMASTER_URL = 'http://www.ticketmaster.no/artist/allsang-pa-grensen-billetter/936441'; // Lenke som åpnes ved Billett-knappen

// Utviklings-debugging, skrur av/på loggføring
const ENABLE_DEBUGGING = true;

// Farger, basert på Allsang på Grensen sin referanse
const PRIMARY_DARKBLUE = const Color(0xFF4EA3B7);
const PRIMARY_BLUE = const Color(0xFF7ED3F7);
const PRIMARY_GREEN = const Color(0xFF009445);
const PRIMARY_GREEN2 = const Color(0xFF8CC63F);
const PRIMARY_YELLOW = const Color(0xFFFFF200);
const PRIMARY_WHITE = const Color(0xFFFFFFFF);

// Simulerte tekst-skygger, brukt i forskjellige steder
const textShadows = [
  Shadow( // bottomLeft
      offset: Offset(-1.5, -1.5),
      color: Colors.black
  ),
  Shadow( // bottomRight
      offset: Offset(1.5, -1.5),
      color: Colors.black
  ),
  Shadow( // topRight
      offset: Offset(1.5, 1.5),
      color: Colors.black
  ),
  Shadow( // topLeft
      offset: Offset(-1.5, 1.5),
      color: Colors.black
  ),
];

/// Loggfører tekst, brukt til printing
void log(String text) {
  if (ENABLE_DEBUGGING) {
    print("[debug] " + text);
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Allsang på Grensen',
    theme: ThemeData(
      primaryColor: PRIMARY_GREEN,
      iconTheme: IconThemeData(
        color: PRIMARY_GREEN,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: PRIMARY_GREEN,
      )
    ),
    home: new LoadingScreen(),
  ));
}

/// Grunnet hvordan innhold hentes fra wordpress må HTML om-formateres
String formatHtmlImages(String data) {
  String originalData = data;

  // Fikser HTML bilde-elementer til å bruke nettsidens bilde-URLer
  data = data.replaceAll(new RegExp(r'src=\"\/wp-content\/'), "src=\"" + WP_URL + "wp-content/");

  // Localhost i Android Studio er på 10.0.02
  data = data.replaceAll(new RegExp(r"localhost"), "10.0.2.2");
  data = data.replaceAll(new RegExp(r"127.0.0.1"), "10.0.2.2");

  if (originalData != data) {
    log("parsed HTML images to actual images");
  }
  return data;
}

/// Lokalt arbeid krever om-dirigering fra vanlig "localhost" til en spesiell IP i Android Studio
String formatLocalhostString(String url) {
  String originalUrl = url;

  // Localhost i Android Studio er på 10.0.02
  url = url.replaceAll(new RegExp(r"localhost"), "10.0.2.2");
  url = url.replaceAll(new RegExp(r"127.0.0.1"), "10.0.2.2");

  if (originalUrl != url) {
    log("parsed URL " + originalUrl + " to " + url);
  }
  return url;
}

/// Wrapper for HTML, automatisk formatering og URL-lenking
class CustomHtml extends Html {
  static void openLink(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
  CustomHtml({
    String data,
    bool useRichText = false,
    TextStyle defaultTextStyle
  }) : super(
    data: formatHtmlImages(data),
    useRichText: useRichText,
    defaultTextStyle: defaultTextStyle,
    onLinkTap: openLink,
  );
}

/// Splash-skjermen
class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreen createState() => new _LoadingScreen();
}

class _LoadingScreen extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    updatePrograms();
    return new SplashScreen(
        seconds: 5,
        navigateAfterSeconds: new MyHomePage(),
        image: new Image.network(LOGO_URL, width: 900.0),
        backgroundColor: PRIMARY_GREEN,
        styleTextUnderTheLoader: new TextStyle(),
        photoSize: 200.0,
        loaderColor: PRIMARY_YELLOW,
    );
  }
}

/// Åpner Ticketmaster lenken i nettleseren
_gotoTicketmaster() async {
  const url = TICKETMASTER_URL;
  if (await canLaunch(url)) {
    await launch(url);
  } else {
  }
}

/// Forside (hjemmeside)
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

_MyHomePageState homePageState;

class _MyHomePageState extends State<MyHomePage> {
  bool loading = false;

  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = [
    NewsFeed(),
    ProgramFeed(),
    AdkomstPage(),
    MapSample(),
    new Text("")
  ];

  _MyHomePageState() {
    homePageState = this;
  }

  //
  void onTap() {
    updatePrograms();
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      _gotoTicketmaster();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Image.network(LOGO_URL),
          onTap: onTap,
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: PRIMARY_GREEN,
        selectedItemColor: PRIMARY_YELLOW,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Allsang')),
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text('Program')),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), title: Text('Adkomst')),
          BottomNavigationBarItem(icon: Icon(Icons.map), title: Text('Kart')),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), title: Text('Billett')),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

List<Widget> feedPosts = new List<Widget>();
List<Widget> programPages = new List<Widget>();

int generating = 0;

/// Henter data fra APIet
Future<Map> fetchData(String apiUrl, [bool full = false]) async {
  String url = apiUrl;
  if (!full) {
    url = API_URL + apiUrl;
  }
  final response =
      await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    log('Failed to fetch data from ' + url);
    throw Exception('Failed to fetch data from ' + url);
  }
}

/// Henter tilleggs-bilde for en post
String getAttachmentURL(Map<String, dynamic> postData) {
  if (postData.containsKey("attachments")) {
    if (postData["attachments"].length > 0) {
      if (postData["attachments"][0].containsKey("url")) {
        String url = postData['attachments'][0]['url'];
        log("attachments, 0, url: " + url);
        return formatLocalhostString(url);
      }
    }
  }
  // Dersom et bilde ikke eksisterer, prøv å finn forhåndsvisningsbildet.
  log("no attachment image, returning thumbnail");
  return getThumbnailURL(postData);
}

/// Henter forhåndsvisningsbildet for en post
String getThumbnailURL(Map<String, dynamic> postData) {
  if (postData.containsKey('thumbnail_images')) {
    if (postData['thumbnail_images'].containsKey('thumbnail')) {
      if (postData['thumbnail_images']['full'].containsKey('url')) {
        String url = postData['thumbnail_images']['full']['url'];
        log("thumbnail_images, full, url: " + url);
        return formatLocalhostString(postData['thumbnail_images']['full']['url']);
      }
      if (postData['thumbnail_images']['thumbnail'].containsKey('url')) {
        String url = postData['thumbnail_images']['thumbnail']['url'];
        log("thumbnail_images, thumbnail, url: " + url);
        return formatLocalhostString(url);
      }
    }
  }
  log("no thumbnail image, returning nothing");
  return "";
}

/// Genererer program-sider (rekursivt)
void generateProgram(_data, n) {
  log("Generating program no. " + n.toString());
  Map<String, dynamic> data = _data;
  if (data.containsKey("posts")) {
    List<dynamic> posts = data['posts'];
    if (posts.length > n) {
      Map<String, dynamic> program = posts[n];
      log("Generating program for " + program['title_plain']);
      fetchData("get_category_posts/?slug=" + program['tags'][0]['title']).then((postsData) =>
      {
        log("Generating posts"),
        programPages.insert(0, new ProgramEntry(program['title'],
            getAttachmentURL(program),
            postsData['posts'])),
      }).then((e) {
        generateProgram(data, n + 1);
      });
    } else {
      log("Generating program end");
      programPages.add(new Container(height: 100.0));
    }
  }
}

/// Reklame Widget som vises der reklamen opptrer
Widget reklameWidget = Card(
  child: ListTile(
    title: Text(""),
    subtitle: Text(""),
    leading: Image.network("", width: 64.0, height: 64.0),
  ),
);

/// Oppdaterer reklamen fra nett
void updateAds() {
  void cbAds(postsData) {
    reklameWidget = new ReklameBanner(postsData['posts']);
  }
  fetchData("get_category_posts/?slug=" + SLUG_REKLAME).then(cbAds);
}

/// Reklamens Widget-klasse, egendefinert widget
class ReklameBanner extends StatelessWidget {
  String title;
  String image;
  String text;
  String url;

  ReklameBanner(List<dynamic> posts) {
    Map<String, dynamic> post = posts[0];
    title = post['title'];
    image = getThumbnailURL(post);
    text = post['content'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.0,
      color: PRIMARY_GREEN2,
      child: ListTile(
          title: CustomHtml(data: title, defaultTextStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          )),
          subtitle: CustomHtml(data: text, defaultTextStyle: TextStyle(
            fontSize: 14.0,
            fontStyle: FontStyle.italic,
          )),
          leading: Image.network(image, width: 64.0, height: 64.0),
        ),
    );
  }
}

// Alle akomst-sidene og titler
Widget adkomstBil = new Text("");
Widget adkomstBilTitle = new Text("Bil");
Widget adkomstBuss = new Text("");
Widget adkomstBussTitle = new Text("Buss");
Widget adkomstTog = new Text("");
Widget adkomstTogTitle = new Text("Tog");
Widget adkomstFot = new Text("");
Widget adkomstFotTitle = new Text("Til fots");

/// Oppdaterer alle 4 adkomsts-sider
void updateAdkomst() {
  void cbAdkomstBil(Map<dynamic, dynamic> postsData) {
    if (postsData.containsKey("posts")) {
      adkomstBil = new CustomHtml(data: postsData['posts'][0]['content']);
      adkomstBilTitle = new Text(postsData['posts'][0]['title_plain']);
    }
  }
  fetchData("get_category_posts/?slug=" + SLUG_ADKOMST_BIL).then(cbAdkomstBil);

  void cbAdkomstBuss(Map<dynamic, dynamic> postsData) {
    if (postsData.containsKey("posts")) {
      adkomstBuss = new CustomHtml(data: postsData['posts'][0]['content']);
      adkomstBussTitle = new Text(postsData['posts'][0]['title_plain']);
    }
  }
  fetchData("get_category_posts/?slug=" + SLUG_ADKOMST_BUSS).then(cbAdkomstBuss);

  void cbAdkomstTog(Map<dynamic, dynamic> postsData) {
    if (postsData.containsKey("posts")) {
      adkomstTog = new CustomHtml(data: postsData['posts'][0]['content']);
      adkomstTogTitle = new Text(postsData['posts'][0]['title_plain']);
    }
  }
  fetchData("get_category_posts/?slug=" + SLUG_ADKOMST_TOG).then(cbAdkomstTog);

  void cbAdkomstFot(Map<dynamic, dynamic> postsData) {
    if (postsData.containsKey("posts")) {
      adkomstFot = new CustomHtml(data: postsData['posts'][0]['content']);
      adkomstFotTitle = new Text(postsData['posts'][0]['title_plain']);
    }
  }
  fetchData("get_category_posts/?slug=" + SLUG_ADKOMST_FOT).then(cbAdkomstFot);
}

/// Allsang-sidens innhold
Widget allsang = new Text("Forside");

/// Oppdaterer Allsang-siden / forsiden
void updateAllsang() {
  log("Updating allsang");

  void cbAllsang(postsData) {
    allsang = new CustomHtml(data: postsData['page']['content']);
  }
  fetchData("https://www.allsangpagrensen.no/api/get_page/?slug=" + SLUG_ALLSANG, true).then(cbAllsang);
}

/// Oppdaterer alle sider med innhold fra APIet
void updatePrograms() {
  log("Updating programs");

  void cbPrograms(postsData) {
    programPages.clear();
    generateProgram(postsData, 0);
  }

  fetchData("get_category_posts/?slug=" + SLUG_PROGRAMS).then(cbPrograms);
  updateAdkomst();
  updateAllsang();
  updateAds();
}

/// Widget som tillater tekst over bilder
Widget OverlaidImage(String url, Widget overlay) {
  return new Container(
      constraints: new BoxConstraints.expand(
        height: 200.0,
      ),
      padding: new EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      decoration: new BoxDecoration(
        image: new DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: overlay
  );
}

/// Individuell dag
class ProgramEntry extends StatelessWidget {
  String title;
  Widget thumbnail;
  Widget page;
  List<ProgramPageEntry> children = new List<ProgramPageEntry>();

  Widget preview;

  ProgramEntry(String title, String thumbnail, List<dynamic> posts) {
    posts.forEach((post) => {
      children.add(new ProgramPageEntry(post))
    });
    this.thumbnail = OverlaidImage(
        thumbnail,
        new Stack(
          children: <Widget>[
            new Positioned(
              left: 0.0,
              bottom: 0.0,
              child: new Text(title,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: Colors.white,
                    shadows: textShadows,
                  )
              ),
            ),
            new Positioned(
              right: 0.0,
              bottom: 0.0,
              child: new Icon(
                Icons.music_note,
                color: Colors.white,
              ),
            ),
          ],
        )
    );
    this.title = title;

    generate();
  }

  void generate() {
    preview = thumbnail;
    page = new Scaffold(
      appBar: new AppBar(
        title: new Text("" + title),
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: preview,
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        Navigator.push(context, new MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}

/// Individuell sang innenfor en dag
class ProgramPageEntry extends StatelessWidget {
  String title;
  String content;
  String excerpt;
  String date;
  Widget preview;
  Widget image;
  String thumburl;
  List<Widget> children;
  Widget page;
  ProgramPageEntry(Map<String, dynamic> data) {
    title = data['title_plain'];
    content = data['content'];
    excerpt = data['excerpt'];
    date = data['date'];
    thumburl = getAttachmentURL(data);
    image = Image.network(thumburl);
    log("Created new ProgramPage");
    generate();
  }

  void generate() {
    log("Generating ProgramPage " + title);
    preview = Card(
      child: OverlaidImage(
        thumburl,
        new Stack(
          children: <Widget>[
            new Positioned(
              left: 0.0,
              bottom: 0.0,
              child: new CustomHtml(useRichText: false, data: title + excerpt, defaultTextStyle: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Colors.white,
                  shadows: textShadows,
                )
              ),
            ),
          ],
        )
      ),
    );
    page = new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
      ),
      body: ListView(
        children: <Widget>[
          image,
          Padding(
            padding: EdgeInsets.all(16.0),
            child: CustomHtml(data: content),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: preview,
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        Navigator.push(context, new MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}

/// Forside, facebook feed etc (skal) vises her
class NewsFeed extends StatefulWidget {
  @override
  State<NewsFeed> createState() => NewsFeedState();
}

class NewsFeedState extends State<NewsFeed> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: ListView(
      children: <Widget>[
        allsang
      ],
      padding: EdgeInsets.only(bottom: 116.0, top: 16.0, right: 16.0, left: 16.0),),
      bottomSheet: reklameWidget
    );
  }
}

/// Programsider (skal) vises her
class ProgramFeed extends StatefulWidget {
  @override
  State<ProgramFeed> createState() => ProgramFeedState();
}

class ProgramFeedState extends State<ProgramFeed> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: ListView(
        children: programPages,
      ),
      bottomSheet: reklameWidget
    );
  }
}

/// Google Maps widget
class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kAllsang = CameraPosition(target: LatLng(59.119414, 11.397113), zoom: 15.4746);

  Widget page;
  void generate() {
    page = new Scaffold(
      appBar: new AppBar(
        title: new Text("Arenakart"),
      ),
      body: ListView(
        children: <Widget>[
         new Image.network(ARENA_URL),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    generate();
    return new Scaffold(
        body: GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: _kAllsang,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete();
          },
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PRIMARY_GREEN,
        onPressed: () {
          Navigator.push(context, new MaterialPageRoute(builder: (context) => page));
        },
        child: Text("ARENA", style: TextStyle(color: PRIMARY_YELLOW)),
      ),
    );
  }
}

/// Adkomst-fane
class AdkomstPage extends StatefulWidget {
  AdkomstPage({Key key}) : super(key: key);
  @override
  _AdkomstPageState createState() => _AdkomstPageState();
}

class _AdkomstPageState extends State<AdkomstPage> {
  int _curPage = 1;

  List<Widget> _pages = [
    adkomstBil,
    adkomstBuss,
    adkomstTog,
    adkomstFot,
  ];

  void onTap(index) {
    setState(() {
      _curPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.center,
            child: _pages.elementAt(_curPage),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar (
          selectedItemColor: PRIMARY_YELLOW,
          backgroundColor: PRIMARY_GREEN2,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), title: adkomstBilTitle),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus), title: adkomstBussTitle),
            BottomNavigationBarItem(icon: Icon(Icons.directions_railway), title: adkomstTogTitle),
            BottomNavigationBarItem(icon: Icon(Icons.directions_walk), title: adkomstFotTitle),
          ],
          type: BottomNavigationBarType.fixed,
          currentIndex: _curPage,
          onTap: onTap,
        )
    );
  }

}
