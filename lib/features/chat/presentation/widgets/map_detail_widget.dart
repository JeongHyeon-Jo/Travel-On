import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';

class MapDetailWidget extends StatelessWidget {
  final TravelPoint location;

  const MapDetailWidget({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          location.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 200,
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: location.location,
                zoom: 15,
              ),
            ),
            onMapReady: (controller) {
              controller.addOverlay(
                NMarker(
                  id: 'marker_${location.id}',
                  position: location.location,
                )..setCaption(NOverlayCaption(
                    text: location.name,
                    textSize: 14,
                    color: Colors.blue,
                    haloColor: Colors.white,
                  )),
              );
            },
          ),
        ),
        SizedBox(height: 10),
        Text(
          location.address.isNotEmpty ? location.address : '주소 정보가 없습니다',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
