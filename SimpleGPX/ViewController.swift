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
import CoreGPX

class ViewController: UIViewController, MKMapViewDelegate, UIDocumentPickerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var coordinateArray = [CLLocationCoordinate2D]()
    var locationManager: CLLocationManager!
    var headingImageView: UIImageView?
    var userHeading: CLLocationDirection?
    var autoRotate = false
    
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
    
    enum GpxTrackingStatus {
        case stoped
        case recording
        case paused
    }
    
    var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.stoped {
        didSet {
            switch gpxTrackingStatus {
            case .stoped:
                print("stoped")
                trackerButton.setImage(UIImage(named: "record"), for: UIControl.State())
                trackerButton.blink(enabled: false)
            case.recording:
                print("recording")
                trackerButton.setImage(UIImage(named: "pause"), for: UIControl.State())
                trackerButton.blink(enabled:false)
            case .paused:
                print ("paused")
                trackerButton.setImage(UIImage(named: "pause"), for: UIControl.State())
                trackerButton.blink()
            }
        }
    }
    
    // Buttons
    var openGPXButton: UIButton
    var followUserButton: UIButton
    var trackerButton: UIButton
    
    let kWhiteBackgroundColor: UIColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)
    
    var arrayLocations: [GPXTrackPoint]
    
    // Inicializador
    required init(coder aDecoder: NSCoder) {
        self.openGPXButton = UIButton(coder: aDecoder)!
        self.followUserButton = UIButton(coder: aDecoder)!
        self.trackerButton = UIButton(coder: aDecoder)!
        self.arrayLocations = []
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
        mapView.addSubview(followUserButton)
        
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
        
        // Gestos
        // Desactivar "Seguir al usuario" cuando movamos el mapa o hagamos zoom
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        panGesture.delegate = self
        mapView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        pinchGesture.delegate = self
        mapView.addGestureRecognizer(pinchGesture)
        
        /* Activar/Desactivar rotación (Compass)
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        mapView.addSubview(compassButton)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCompassTap))
        compassButton.addGestureRecognizer(tapGestureRecognizer)
        */
    }

    @objc func handleCompassTap() {
        // Implement your feature when the compass button tapped.
        autoRotate = !autoRotate
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
        self.mapView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.mapView.setVisibleMapRect(routeLine.boundingMapRect, animated: true)
    }
    
    func clearOverlays(){
        let overlays = mapView.overlays
        self.mapView.removeOverlays(overlays)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 2.0
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if views.last?.annotation is MKUserLocation {
            addHeadingView(toAnnotationView: views.last!)
        }
    }
    
    func addHeadingView(toAnnotationView annotationView: MKAnnotationView) {
        if headingImageView == nil {
            let image = UIImage(named: "heading")
            headingImageView = UIImageView(image: image)
            headingImageView!.frame = CGRect(x: (annotationView.frame.size.width - image!.size.width)/2, y: (annotationView.frame.size.height - image!.size.height)/2, width: image!.size.width, height: image!.size.height)
            annotationView.insertSubview(headingImageView!, at: 0)
            headingImageView!.isHidden = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, followUser {
            mapView.setCenter(location.coordinate, animated: true)
        }
        if gpxTrackingStatus == .recording {
            print("\(locations.last?.coordinate.latitude ?? 0) \(locations.last?.coordinate.longitude ?? 0)")
            // 29-08-2019 - Añadimos punto al fichero GPX
            if let latitude = locations.last?.coordinate.latitude {
                if let longitude = locations.last?.coordinate.longitude {
                    arrayLocations.append(GPXTrackPoint(latitude: latitude, longitude: longitude))
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        updateHeadingRotation(autoRotate: autoRotate, newHeading: newHeading)
    }
    
    func updateHeadingRotation(autoRotate: Bool, newHeading: CLHeading) {
        if let heading = locationManager.heading?.trueHeading,
        let headingImageView = headingImageView {
            
            headingImageView.isHidden = false
            let rotation = CGFloat(heading/180 * Double.pi)
            headingImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }
        
        if autoRotate {
            // Rotar el mapa para apuntar hacia dónde estemos mirando
            mapView.camera.heading = newHeading.magneticHeading
            mapView.setCamera(mapView.camera, animated: true)
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
        switch gpxTrackingStatus {
        case .stoped:
            gpxTrackingStatus = .recording
        case .recording:
            gpxTrackingStatus = .paused
            // Avisar que estamos en modo pausa
            // Preguntar si desea acabar la grabación
            let alert = UIAlertController(title: "Paused", message: "Recording paused", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        case .paused:
            // Preguntar si desea acabar la grabación
            let alert = UIAlertController(title: "Stop or continue recording?", message: "Stop or continue recording?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { action in
                self.gpxTrackingStatus = .recording
            }))
            alert.addAction(UIAlertAction(title: "Stop", style: .cancel, handler: { action in
                self.gpxTrackingStatus = .stoped
                // Guardamos y limpiamos el array
                GPXUtils.shared.saveGPX(withArray: self.arrayLocations)
                self.arrayLocations.removeAll()
            }))
            self.present(alert, animated: true)
        }
        
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

extension UIButton {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.bounds.contains(point) ? self : nil
    }
    func blink(enabled: Bool = true, duration: CFTimeInterval = 1.0, stopAfter: CFTimeInterval = 0.0 ) {
        enabled ? (UIView.animate(withDuration: duration,
            delay: 0.0,
            options: [.curveEaseInOut, .autoreverse, .repeat],
            animations: { [weak self] in self?.alpha = 0.2 },
            completion: { [weak self] _ in self?.alpha = 1.0 })) : self.layer.removeAllAnimations()
        if !stopAfter.isEqual(to: 0.0) && enabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + stopAfter) { [weak self] in
                self?.layer.removeAllAnimations()
            }
        }
    }
}
