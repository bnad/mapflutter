// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'page.dart';

class PlacePolygonPage extends GoogleMapExampleAppPage {
  PlacePolygonPage() : super(const Icon(Icons.linear_scale), 'Place polygon');

  @override
  Widget build(BuildContext context) {
    return const PlacePolygonBody();
  }
}

class PlacePolygonBody extends StatefulWidget {
  const PlacePolygonBody();

  @override
  State<StatefulWidget> createState() => PlacePolygonBodyState();
}

class PlacePolygonBodyState extends State<PlacePolygonBody> {
  PlacePolygonBodyState();

  static final LatLng center = const LatLng(10.841505288357736, 106.80946768863981);
  MarkerId selectedMarker;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController controller;
  Map<PolygonId, Polygon> polygons = <PolygonId, Polygon>{};
  Map<PolygonId, double> polygonOffsets = <PolygonId, double>{};
  int _polygonIdCounter = 0;
  PolygonId selectedPolygon;
  int _markerIdCounter = 1;
  String responseText = '';

  // Values when toggling polygon color
  int strokeColorsIndex = 0;
  int fillColorsIndex = 0;
  List<Color> colors = <Color>[
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.pink,
  ];

  // Values when toggling polygon width
  int widthsIndex = 0;
  List<int> widths = <int>[10, 20, 5];

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPolygonTapped(PolygonId polygonId) {
    setState(() {
      selectedPolygon = polygonId;
    });
  }

  void _remove() {
    setState(() {
      if (polygons.containsKey(selectedPolygon)) {
        polygons.remove(selectedPolygon);
      }
      selectedPolygon = null;
    });
  }

  void _add() {
    final int polygonCount = polygons.length;

    if (polygonCount == 12) {
      return;
    }

    final String polygonIdVal = 'polygon_id_$_polygonIdCounter';
    final PolygonId polygonId = PolygonId(polygonIdVal);

    final Polygon polygon = Polygon(
      polygonId: polygonId,
      consumeTapEvents: true,
      strokeColor: Colors.orange,
      strokeWidth: 2,
      fillColor: Colors.green,
      points: _createPoints(),
      onTap: () {
        _onPolygonTapped(polygonId);
      },
    );

    setState(() {
      polygons[polygonId] = polygon;
      polygonOffsets[polygonId] = _polygonIdCounter.ceilToDouble();
      // increment _polygonIdCounter to have unique polygon id each time
      _polygonIdCounter++;
    });
  }

  void _toggleGeodesic() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        geodesicParam: !polygon.geodesic,
      );
    });
  }

  void _toggleVisible() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        visibleParam: !polygon.visible,
      );
    });
  }

  void _changeStrokeColor() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        strokeColorParam: colors[++strokeColorsIndex % colors.length],
      );
    });
  }

  void _changeFillColor() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        fillColorParam: colors[++fillColorsIndex % colors.length],
      );
    });
  }

  void _changeWidth() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        strokeWidthParam: widths[++widthsIndex % widths.length],
      );
    });
  }

  void _onMarkerDragEnd(MarkerId markerId, LatLng newPosition) async {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
                content: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 66),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Old position: ${tappedMarker.position}'),
                        Text('New position: $newPosition'),
                      ],
                    )));
          });
    }
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        if (markers.containsKey(selectedMarker)) {
          final Marker resetOld = markers[selectedMarker]
              .copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markers[selectedMarker] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker = tappedMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );
        markers[markerId] = newMarker;
      });
    }
  }
  void _addHoles() {
    final int markerCount = markers.length;

    if (markerCount == 12) {
      return;
    }

    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
        center.latitude ,
            //+ sin(_markerIdCounter * pi / 6.0) / 200.0,
        center.longitude,
            //+ cos(_markerIdCounter * pi / 6.0) / 200.0,
      ),
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () {
        _onMarkerTapped(markerId);
      },
      onDragEnd: (LatLng position) {
        _onMarkerDragEnd(markerId, position);
      },
    );

    setState(() {
      markers[markerId] = marker;
      double areaRectangle = sqrt(
          pow(_createPoints()[1].longitude - _createPoints()[2].longitude, 2) +
              pow(_createPoints()[1].latitude - _createPoints()[2].latitude, 2)
      ) * sqrt(
          pow(_createPoints()[2].longitude - _createPoints()[3].longitude, 2) +
              pow(_createPoints()[2].latitude - _createPoints()[3].latitude, 2)
      );

      double area1 = 0.5*(
          (_createPoints()[1].longitude - marker.position.longitude)*
              (_createPoints()[2].latitude - marker.position.latitude)
              -
              (_createPoints()[2].longitude - marker.position.longitude)*
                  (_createPoints()[1].latitude - marker.position.latitude)
      ).abs();
      double area2 = 0.5*(
          (_createPoints()[2].longitude - marker.position.longitude)*
              (_createPoints()[3].latitude - marker.position.latitude)
              -
              (_createPoints()[3].longitude - marker.position.longitude)*
                  (_createPoints()[2].latitude - marker.position.latitude)
      ).abs();
      double area3 = 0.5*(
          (_createPoints()[3].longitude - marker.position.longitude)*
              (_createPoints()[0].latitude - marker.position.latitude)
              -
              (_createPoints()[0].longitude - marker.position.longitude)*
                  (_createPoints()[3].latitude - marker.position.latitude)
      ).abs();
      double area4 = 0.5*(
          (_createPoints()[0].longitude - marker.position.longitude)*
              (_createPoints()[1].latitude - marker.position.latitude)
              -
              (_createPoints()[1].longitude - marker.position.longitude)*
                  (_createPoints()[0].latitude - marker.position.latitude)
      ).abs();
       double areaTotal = area4 + area3 + area2 + area1;

      print(areaTotal.toString());
      print(areaRectangle.toString());
      if(areaTotal - areaRectangle >=0.000000001) {
        responseText = 'Đang ở ngoài';
      }
      else{
        responseText = 'Đang ở trong';
      }
    });
  }

  void _removeHoles() {
    final Polygon polygon = polygons[selectedPolygon];
    setState(() {
      polygons[selectedPolygon] = polygon.copyWith(
        holesParam: <List<LatLng>>[],
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 500.0,
            height: 500.0,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.841662444147342, 106.80980171160871),
                zoom: 15.0,
              ),
              markers: Set<Marker>.of(markers.values),
              polygons: Set<Polygon>.of(polygons.values),
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            TextButton(
                              child: const Text('add'),
                              onPressed: _add,
                            ),
                            // TextButton(
                            //   child: const Text('remove'),
                            //   onPressed: (selectedPolygon == null) ? null : _remove,
                            // ),
                            // TextButton(
                            //   child: const Text('toggle visible'),
                            //   onPressed:
                            //       (selectedPolygon == null) ? null : _toggleVisible,
                            // ),
                            // TextButton(
                            //   child: const Text('toggle geodesic'),
                            //   onPressed: (selectedPolygon == null)
                            //       ? null
                            //       : _toggleGeodesic,
                            // ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            TextButton(
                              child: const Text('add marker'),
                              onPressed: _addHoles,
                            ),
                            // TextButton(
                            //   child: const Text('remove holes'),
                            //   onPressed: (selectedPolygon == null)
                            //       ? null
                            //       : ((polygons[selectedPolygon].holes.isEmpty)
                            //           ? null
                            //           : _removeHoles),
                            // ),
                            // TextButton(
                            //   child: const Text('change stroke width'),
                            //   onPressed:
                            //       (selectedPolygon == null) ? null : _changeWidth,
                            // ),
                            // TextButton(
                            //   child: const Text('change stroke color'),
                            //   onPressed: (selectedPolygon == null)
                            //       ? null
                            //       : _changeStrokeColor,
                            // ),
                            // TextButton(
                            //   child: const Text('change fill color'),
                            //   onPressed: (selectedPolygon == null)
                            //       ? null
                            //       : _changeFillColor,
                            // ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                Text(responseText, style:
                responseText == 'Đang ở ngoài' ?
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red) :
                TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),)
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<LatLng> _createPoints() {
    final List<LatLng> points = <LatLng>[];
    final double offset = _polygonIdCounter.ceilToDouble();
    //  10.841496823955932, 106.80981270190118
    points.add(_createLatLng(10.841538144408277, 106.80947453695457));
    points.add(_createLatLng(10.841451211353686, 106.80938937681391));
    points.add(_createLatLng(10.841396548889756, 106.80944503265388));
    points.add(_createLatLng(10.841482164792689, 106.80953086334681));
    return points;
  }


  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }
}
