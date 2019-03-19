import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MaterialApp(
    title: 'Navigation Basics',
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1;
  final _widgetOptions = [
    Text('Index 0: Allsang'),
    Text('Index 1: Program'),
    AdkomstPage(),
    MapSample(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Allsang'),
        actions: <Widget>[],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Allsang')),
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text('Program')),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), title: Text('Adkomst')),
          BottomNavigationBarItem(icon: Icon(Icons.map), title: Text('Kart')),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        fixedColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kAllsang = CameraPosition(target: LatLng(59.119414, 11.397113), zoom: 14.4746);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kAllsang,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete();
        },
      )
    );
  }
}

class AdkomstPage extends StatefulWidget {
  AdkomstPage({Key key}) : super(key: key);
  @override
  _AdkomstPageState createState() => _AdkomstPageState();
}

class _AdkomstPageState extends State<AdkomstPage> {
  int _curPage = 1;

  List<Widget> _pages = [
    Text('[Adkomstintruksjon for bil]'),
    Text('[Adkomstintruksjon for buss]'),
    Text('[Adkomstintruksjon for tog]'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages.elementAt(_curPage),
        bottomNavigationBar: BottomNavigationBar (
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), title: Text('Bil')),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus), title: Text('Buss')),
            BottomNavigationBarItem(icon: Icon(Icons.directions_railway), title: Text('Tog')),
          ],
          type: BottomNavigationBarType.fixed,
          currentIndex: _curPage,
          onTap: _onItemTapped,
        )
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 2) {
        fetchPost().then((ul) {
          List<Widget> cards = List();
          ul.list.forEach((user) {
            cards.add(user.toWidget());
          });
          _pages.removeAt(2);
          _pages.insert(2, ListView(
              children: cards
          ));
        });
      }
      _curPage = index;
    });
  }


}


Future<UserList> fetchPost() async {
  final response =
  await http.get('http://server.tycoon.community:30124/status/map/positions.json');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    return UserList.fromJson(jsonDecode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

final classIcons = [
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.motorcycle,
  Icons.directions_car,
  Icons.local_shipping,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_bike,
  Icons.directions_boat,
  Icons.airplanemode_active,
  Icons.airplanemode_active,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.directions_car,
  Icons.train,
];

class UserListing {
  String name;
  int source;
  int id;
  Map<String, dynamic> position;
  Map<String, dynamic> vehicle;
  Map<String, dynamic> job;

  UserListing({this.name, this.source, this.id, this.position, this.vehicle, this.job});

  Widget toWidget() {
    List<Widget> items = [
      ListTile(
        leading: Icon(Icons.person),
        title: Text(this.name + ' (${this.id})'),
        subtitle: Text(this.job['name']),
      ),
    ];
    if (this.vehicle['vehicle_type'] == 'foot') {
      items.add(ButtonTheme.bar(
          child: ButtonBar(
              children: <Widget>[
                Icon(Icons.directions_run),
                Text("On foot"),
              ]
          )
      ));
    } else {
      items.add(ButtonTheme.bar(
          child: ButtonBar(
              children: <Widget>[
                Icon(classIcons[this.vehicle['vehicle_class']]),
                Text("Driving a ${this.vehicle['vehicle_name']}"),
                FlatButton(
                  child: Text("EJECT"),
                  onPressed: () {},
                )
              ]
          )
      ));
    }
    return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items,
        )
    );
  }

}

class UserList {
  final List list;

  UserList({this.list});

  factory UserList.fromJson(Map<String, dynamic> json) {
    List<UserListing> list = new List<UserListing>();
    json['players'].forEach((v) {
      list.add(UserListing(name: v[0], source: v[1], id: v[2], position: v[3], vehicle: v[4], job: v[5]));
    });
    return UserList(list: list);
  }
}

