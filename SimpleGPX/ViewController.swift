//
//  ViewController.swift
//  SimpleGPX
//
//  Created by Jose Gabriel Ferrer on 16/04/2019.
//  Copyright © 2019 Jose Gabriel Ferrer. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MobileCoreServices

class ViewController: UIViewController, MKMapViewDelegate, UIDocumentPickerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var coordinateArray = [CLLocationCoordinate2D]()
    var locationManager: CLLocationManager!
    
    let kButtonSmallSize: CGFloat = 60.0
    let kButtonLargeSize: CGFloat = 100.0
    let kButtonSeparation: CGFloat = 20.0
    
    var followUser: Bool = true {
        didSet {
            if followUser {
                followUserButton.setImage(UIImage(named: "follow_user"), for: UIControl.State())
                mapView.setCenter((mapView.userLocation.coordinate), animated: true)
                
            } else {
                followUserButton.setImage(UIImage(named: "follow_user_disabled"), for: UIControl.State())
            }
        }
    }
    
    // Buttons
    var openGPXButton: UIButton
    var followUserButton: UIButton
    var trackerButton: UIButton
    
    let kWhiteBackgroundColor: UIColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)
    
    // Inicializador
    required init(coder aDecoder: NSCoder) {
        self.openGPXButton = UIButton(coder: aDecoder)!
        self.followUserButton = UIButton(coder: aDecoder)!
        self.trackerButton = UIButton(coder: aDecoder)!
        super.init(coder: aDecoder)!
        followUser = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.openFromOutsideNotification(_:)), name: Notification.Name.openFromOutsideNotification, object: nil)
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            mapView.showsUserLocation = true
            let center = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 8.90, longitude: -79.50)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
        }
        
        let yCenterForButtons: CGFloat = mapView.frame.height - kButtonLargeSize/2 - 5 //center Y of start
        
        // Start/Pause button
        let trackerW: CGFloat = kButtonLargeSize
        let trackerH: CGFloat = kButtonLargeSize
        let trackerX: CGFloat = self.mapView.frame.width/2 - 0.0 // Center of start
        let trackerY: CGFloat = yCenterForButtons
        trackerButton.frame = CGRect(x: 0, y:0, width: trackerW, height: trackerH)
        trackerButton.center = CGPoint(x: trackerX, y: trackerY)
        trackerButton.layer.cornerRadius = trackerW/2
        trackerButton.backgroundColor = .clear
        trackerButton.setImage(UIImage(named: "record"), for: UIControl.State())
        trackerButton.addTarget(self, action: #selector(ViewController.trackerButtonTapped), for: .touchUpInside)
        trackerButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        mapView.addSubview(trackerButton)
        
        // Botón para seguir al usuario
        let followW: CGFloat = kButtonSmallSize
        let followH: CGFloat = kButtonSmallSize
        let followX: CGFloat = trackerX - trackerW/2 - kButtonSeparation - followW/2
        let followY: CGFloat = yCenterForButtons
        followUserButton.frame = CGRect(x: 0, y: 0, width: followW, height: followH)
        followUserButton.center = CGPoint(x: followX, y: followY)
        followUserButton.layer.cornerRadius = followW/2
        followUserButton.backgroundColor = kWhiteBackgroundColor
        followUserButton.setImage(UIImage(named: "follow_user"), for: UIControl.State())
        followUserButton.setImage(UIImage(named: "follow_user"), for: .highlighted)
        followUserButton.addTarget(self, action: #selector(ViewController.followButtonTroggler), for: .touchUpInside)
        followUserButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        
        // Folder button
        let folderW: CGFloat = kButtonSmallSize
        let folderH: CGFloat = kButtonSmallSize
        let folderX: CGFloat = trackerX + trackerW/2 + kButtonSeparation + folderW/2
        let folderY: CGFloat = yCenterForButtons
        openGPXButton.frame = CGRect(x: 0, y: 0, width: folderW, height: folderH)
        openGPXButton.center = CGPoint(x: folderX, y: folderY)
        openGPXButton.setImage(UIImage(named: "open_gpx"), for: UIControl.State())
        openGPXButton.setImage(UIImage(named: "open_gpx"), for: .highlighted)
        openGPXButton.addTarget(self, action: #selector(ViewController.openGPXLocal), for: .touchUpInside)
        openGPXButton.backgroundColor = .clear
        openGPXButton.layer.cornerRadius = folderW/2
        openGPXButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        mapView.addSubview(openGPXButton)
        
        mapView.addSubview(followUserButton)
        
        // Gestos
        // Desactivar "Seguir al usuario" cuando movamos el mapa o hagamos zoom
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        panGesture.delegate = self
        mapView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        pinchGesture.delegate = self
        mapView.addGestureRecognizer(pinchGesture)
        
    }

    @objc func stopFollowingUser(_ gesture: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Map Utils and Delegate
    func drawTracksOnMap(){
        self.clearOverlays()
        guard self.coordinateArray.count > 0 else { return }
        var routeLine: MKPolyline
        routeLine = MKPolyline(coordinates: self.coordinateArray, count: self.coordinateArray.count)
        self.mapView.addOverlay(routeLine)
        self.mapView.setCenter(self.coordinateArray[self.coordinateArray.count/2], animated: true)
        self.mapView.setVisibleMapRect(routeLine.boundingMapRect, animated: true)
    }
    
    func clearOverlays(){
        let overlays = mapView.overlays
        self.mapView.removeOverlays(overlays)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, followUser {
            mapView.setCenter(location.coordinate, animated: true)
        }
    }
    
    // MARK: DocumentPicker Delegate
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.coordinateArray = GPXUtils.shared.getCoordinateArray(withURL: url.absoluteString)
        self.followUser = false
        self.drawTracksOnMap()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    ///
    /// Función usada cuando se pulsa el botón de "Seguir al usuario"
    ///
    @objc func followButtonTroggler() {
        self.followUser = !self.followUser
    }
    
    ///
    /// Botón "REC" / "PAUSE" / "RESUME" pulsado
    ///
    @objc func trackerButtonTapped() {
        print("Record Track")
    }
    
    @objc func openGPXLocal() {
        // Para leer fichero local
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }
 
    @objc func openFromOutsideNotification(_ notification: Notification) {
        coordinateArray = notification.userInfo?["coordinateArray"] as! [CLLocationCoordinate2D]
        self.followUser = false
        self.drawTracksOnMap()
    }
    
    // MARK: UNUSED
    @IBAction func readGPXFromURL(_ sender: UIButton) {
        // Para leer desde URL
        let alert = UIAlertController(title: "Enter the GPX URL:", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "GPX URL here..."
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let url = alert.textFields?.first?.text {
                self.coordinateArray = GPXUtils.shared.getCoordinateArray(withURL: url)
                self.drawTracksOnMap()
            }
        }))
        self.present(alert, animated: true)
    }
    
}

extension Notification.Name {
    public static let openFromOutsideNotification = Notification.Name(rawValue: "openExternalFile")
}
