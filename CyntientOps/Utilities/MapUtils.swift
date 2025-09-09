import MapKit

extension MKCoordinateRegion {
    static func fit(points: [CLLocationCoordinate2D],
                    paddingFactor: Double = 1.3,
                    minSpan: CLLocationDegrees = 0.008) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.741, longitude: -73.989),
                                      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        if points.count == 1 {
            return MKCoordinateRegion(center: first,
                                      span: MKCoordinateSpan(latitudeDelta: minSpan, longitudeDelta: minSpan))
        }
        let lats = points.map { $0.latitude }
        let lons = points.map { $0.longitude }
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2,
                                            longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(minSpan, (lats.max()! - lats.min()!) * paddingFactor),
                                    longitudeDelta: max(minSpan, (lons.max()! - lons.min()!) * paddingFactor))
        return MKCoordinateRegion(center: center, span: span)
    }
}

