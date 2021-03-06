//
//  SettingsViewController.swift
//  oor-ios
//
//  Created by Oriol Marí Marqués on 14/02/2018.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate {
 
    let defaults = UserDefaults(suiteName: "group.oor")
    
    @IBOutlet weak var eidTextField: UITextField!
    @IBOutlet weak var iidTextField: UITextField!
    @IBOutlet weak var mapResolverTextField: UITextField!
    @IBOutlet weak var mapServerTextField: UITextField!
    @IBOutlet weak var mapServerKeyTextField: UITextField!
    @IBOutlet weak var proxyEtrAddressTextField: UITextField!
    @IBOutlet weak var dnsServerTextField: UITextField!
    @IBOutlet weak var saveLabel: UILabel!
    @IBOutlet weak var natSwitch: UISwitch!
    @IBOutlet weak var stepperTextField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    
    @IBAction func stepperChanged(_ sender: Any) {
        stepperTextField.text = String(Int(stepper.value))
    }
    
    @IBAction func saveButton(_ sender: Any) {
        var alert:UIAlertController? = nil;
        var hasAlert = false
        var message = ""
        if !validateIpAddress(ip: eidTextField.text!){
            message = message + "* Please enter a valid EID address (IPv4 / IPv6)\n"
            hasAlert = true
        }
        if !natSwitch.isOn {
            if !validateIpAddress(ip: mapResolverTextField.text!){
                message = message + "* Please enter a valid Map Resolver address (IPv4)\n"
                hasAlert = true
            }
            if !validateIpAddress(ip: proxyEtrAddressTextField.text!){
                message = message + "* Please enter a valid Proxy ETR address (IPv4)\n"
                hasAlert = true
            }
        }
        if !validateIpAddress(ip: mapServerTextField.text!){
            message = message + "* Please enter a valid Map Server address (IPv4)\n"
            hasAlert = true
        }
        if !validateIpAddress(ip: dnsServerTextField.text!){
            message = message + "* Please enter a valid DNS server address (IPv4 / IPv6)\n"
            hasAlert = true
        }
        if validateIPv4(ip: eidTextField.text!){
            if !validateIPv4(ip: dnsServerTextField.text!){
                message = message + "* The DNS server address should be IPv4 (same family address than EID)\n"
                hasAlert = true
            }
        }else{
            if !validateIPv6(ip: dnsServerTextField.text!){
                message = message + "* The DNS server address should be IPv6 (same family address than EID)\n"
                hasAlert = true
            }
        }
        
        if (iidTextField != nil){
            let iid = Int(iidTextField.text!)
            if iid == nil || iid! < 0 || iid! > 16777215 {
                message = message + "* Please enter a valid IID [0 - 16777215]\n"
                hasAlert = true
            }
        }else{
            iidTextField.text = "0"
        }
        
        if (hasAlert){
            alert = UIAlertController(title: "Invalid Configuration:",message: message, preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert!, animated: true)
        }else{
            saveConfig()
            saveLabel.text = "Configuration saved!"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.eidTextField.delegate = self
        self.iidTextField.delegate = self
        self.mapResolverTextField.delegate = self
        self.mapServerTextField.delegate = self
        self.mapServerKeyTextField.delegate = self
        self.proxyEtrAddressTextField.delegate = self
        self.dnsServerTextField.delegate = self
        loadConfig()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func loadConfig() {
        eidTextField.text = defaults?.string(forKey: "eid")
        if defaults?.string(forKey:"iid") == nil {
            iidTextField.text = "0"
        }
        else {
            iidTextField.text = defaults?.string(forKey: "iid")
        }
        mapResolverTextField.text = defaults?.string(forKey: "mapResolver")
        mapServerTextField.text = defaults?.string(forKey: "mapServer")
        mapServerKeyTextField.text = defaults?.string(forKey: "mapServerKey")
        proxyEtrAddressTextField.text = defaults?.string(forKey: "proxyEtrAddress")
        dnsServerTextField.text = defaults?.string(forKey: "dnsServer")
        natSwitch.isOn = (defaults?.bool(forKey: "nat"))!
        if defaults?.string(forKey: "debugString") == nil {
            stepper.value = 0
            stepperTextField.text = "0"
        } else {
            stepper.value = (defaults?.double(forKey: "debug"))!
            stepperTextField.text = defaults?.string(forKey: "debugString")
        }
    }
    
    func saveConfig() {
        defaults?.set(eidTextField.text, forKey: "eid")
        if (iidTextField.text?.isEmpty)! {
            defaults?.set("0", forKey: "iid")
        }
        else {
            defaults?.set(iidTextField.text, forKey: "iid")
        }
        defaults?.set(mapResolverTextField.text ,forKey: "mapResolver")
        defaults?.set(mapServerTextField.text, forKey: "mapServer")
        defaults?.set(mapServerKeyTextField.text, forKey: "mapServerKey")
        defaults?.set(proxyEtrAddressTextField.text, forKey: "proxyEtrAddress")
        defaults?.set(dnsServerTextField.text, forKey: "dnsServer")
        defaults?.set(natSwitch.isOn, forKey: "nat")
        defaults?.set(stepper.value, forKey: "debug")
        defaults?.set(stepperTextField.text, forKey: "debugString")
        defaults?.set(true, forKey: "firstLaunch")
        defaults?.addSuite(named: "group.oor")
        writeConfigFile()
    }
    
    func writeConfigFile() {
        var config = ""
        let eid:String = (defaults?.string(forKey: "eid"))!
        let petr:String = (defaults?.string(forKey: "proxyEtrAddress"))!
        config.append("#       *** noroot_OOR EXAMPLE CONFIG FILE ***\n\n\n")
        config.append("# General configuration\n")
        config.append("#      debug: Debug levels [0..3]\n")
        config.append("#      map-request-retries: Additional Map-Requests to send per map cache miss\n")
        config.append("#      encapsulation: Encapsulation that will use noroot_OOR in the data plane. Could \n")
        config.append("#        be LISP or VXLAN-GPE. LISP is selected by default\n\n")
        config.append("debug                  = \(defaults?.string(forKey: "debugString") ?? "")\n")
        config.append("map-request-retries    = 2\n")
        config.append("encapsulation          = LISP\n\n\n")
        config.append("#\n")
        config.append("# operating mode can be any of:\n")
        config.append("# xTR, RTR, MN, MS\n")
        config.append("#\n\n")
        config.append("operating-mode         = MN\n")
        config.append("# RLOC Probing configuration\n")
        config.append("#   rloc-probe-interval: interval at which periodic RLOC probes are sent\n")
        config.append("#     (seconds). A value of 0 disables RLOC Probing\n")
        config.append("#   rloc-probe-retries: RLOC Probe retries before setting the locator with\n")
        config.append("#     status down. [0..5]\n")
        config.append("#   rloc-probe-retries-interval: interval at which RLOC probes retries are\n")
        config.append("#     sent (seconds) [1..#rloc-probe-interval]\n\n")
        config.append("rloc-probing {\n")
        config.append("    rloc-probe-interval             = 30\n")
        config.append("    rloc-probe-retries              = 2\n")
        config.append("    rloc-probe-retries-interval     = 5\n")
        config.append("}\n\n\n")
        config.append("# NAT Traversal configuration. \n")
        config.append("#   nat_traversal_support: check if the node is behind NAT\n\n")
        config.append("nat_traversal_support = \(natSwitch.isOn)\n\n\n")
        if !natSwitch.isOn {
            config.append("# Encapsulated Map-Requests are sent to this map-resolver\n")
            config.append("# You can define several map-resolvers. Encapsulated Map-Request messages will\n")
            config.append("# be sent to only one.\n")
            config.append("#   address: IPv4 or IPv6 address of the map resolver\n")
            config.append("map-resolver        = {\n")
            config.append("        \(defaults?.string(forKey: "mapResolver") ?? "")\n")
            config.append("}\n\n\n")
        }
        config.append("# Map-Registers are sent to this map-server\n")
        config.append("# You can define several map-servers. Map-Register messages will be sent to all\n")
        config.append("# of them.\n")
        config.append("#   address: IPv4 or IPv6 address of the map-server\n")
        config.append("#   key-type: Only 1 supported (HMAC-SHA-1-96)\n")
        config.append("#   key: password to authenticate with the map-server\n")
        config.append("#   proxy-reply [on/off]: Configure map-server to Map-Reply on behalf of the xTR\n\n")
        config.append("map-server {\n")
        config.append("        address     = \(defaults?.string(forKey: "mapServer") ?? "")\n")
        config.append("        key-type    = 1\n")
        config.append("        key         = \(defaults?.string(forKey: "mapServerKey") ?? "")\n")
        config.append("        proxy-reply = off\n")
        config.append("}\n\n\n")
        config.append("# List of PITRs to SMR on handover\n")
        config.append("#   address: IPv4 or IPv6 address of the Proxy-ITR\n")
        config.append("#   Current LISP beta-network (lisp4.net/lisp6.net) PITR addresses\n\n")
        config.append("proxy-itrs = {\n")
        config.append("        69.31.31.98,\n")
        config.append("        129.250.1.63,\n")
        config.append("        217.8.98.33,\n")
        config.append("        217.8.98.35,\n")
        config.append("        147.83.131.33,\n")
        config.append("        203.181.249.172,\n")
        config.append("        202.51.247.10,\n")
        config.append("        2001:590::451f:1f62,\n")
        config.append("        2001:418:0:1000::63,\n")
        config.append("        2001:40B0:7500:205:1::E,\n")
        config.append("        2001:40B0:7500:205:1::12,\n")
        config.append("        2001:200:e000:17::172\n")
        config.append("}\n\n\n")
        config.append("# IPv4 / IPv6 EID of the node.\n")
        config.append("# Two kind of rlocs can be defined:\n")
        config.append("#   -> rloc-address: Specifies directly the rloc of the interface\n")
        config.append("#   -> rloc-iface: Specifies the interface associated with the RLOC\n")
        config.append("#\n")
        config.append("#   eid-prefix: EID prefix (IPvX/mask) of the mapping\n")
        config.append("#   address: IPv4 or IPv6 address of the rloc. Address should exist and\n")
        config.append("#      be assigned to an UP interface during starting process otherwise\n")
        config.append("#      it is discarded\n")
        config.append("#   interface: interface containing the RLOCs associated to this mapping\n")
        config.append("#   afi: 4 to use IPv4 address of the interface and 6 to use IPv6 address\n")
        config.append("#     of the interface\n")
        config.append("#   priority [0-255]: Priority for the IPvX RLOC of the interface. Locators\n")
        config.append("#     with lower values are more preferable. This is used for both incoming\n")
        config.append("#     policy announcements and outcoming traffic policy management.\n")
        config.append("#   weight [0-255]: When priorities are the same for multiple RLOCs, the Weight\n")
        config.append("#     indicates how to balance unicast traffic between them.\n")
        config.append("database-mapping {\n")
        if validateIPv4(ip: eid) {
            config.append("        eid-prefix     = \(eid)/32\n")
        } else if validateIPv6(ip: eid) {
            config.append("        eid-prefix     = \(eid)/128\n")
        }
        config.append("        iid            = \(defaults?.string(forKey: "iid") ?? "")\n")
        config.append("        rloc-iface{\n")
        config.append("           interface     = en0\n")
        config.append("           ip_version    = 4\n")
        config.append("           priority      = 3\n")
        config.append("           weight        = 1\n")
        config.append("        }\n\n")
        config.append("        rloc-iface{\n")
        config.append("           interface     = en0\n")
        config.append("           ip_version    = 6\n")
        config.append("           priority      = 1\n")
        config.append("           weight        = 1\n")
        config.append("        }\n\n")
        config.append("        rloc-iface{\n")
        config.append("           interface     = pdp_ip0\n")
        config.append("           ip_version    = 4\n")
        config.append("           priority      = 2\n")
        config.append("           weight        = 1\n")
        config.append("        }\n\n")
        config.append("        rloc-iface{\n")
        config.append("           interface     = pdp_ip0\n")
        config.append("           ip_version    = 6\n")
        config.append("           priority      = 2\n")
        config.append("           weight        = 1\n")
        config.append("        }\n\n");
        config.append("}\n\n");
        if !natSwitch.isOn {
            config.append("proxy-etr-ipv4 {\n")
            config.append("        address     = \(petr)\n")
            config.append("        priority    = 1\n")
            config.append("        weight      = 100\n")
            config.append("}\n\n")
            config.append("proxy-etr-ipv6 {\n")
            config.append("        address     = \(petr)\n")
            config.append("        priority    = 1\n")
            config.append("        weight      = 100\n")
            config.append("}\n\n");
        }

        
        print(config)
        
        let file = "oor.conf" //this is the file. we will write to and read from it
        
        if let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.oor") {
            let fileURL = dir.appendingPathComponent(file)
            //writing
            do {
                try config.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch { print("ERROR \(error)")}
        }

    }
    
    func validateIPv4(ip: String) -> Bool {
        var sin = sockaddr_in()
        if ip.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            // IPv4 peer.
            return true
        }
        return false
    }
    
    func validateIPv6(ip: String) -> Bool {
        var sin6 = sockaddr_in6()
        if ip.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
            // IPv6 peer.
            return true
        }
        return false
    }
    
    func validateIpAddress(ip: String) -> Bool {
        if (validateIPv4(ip:ip)) {
            return true
        }
        if (validateIPv6(ip:ip)) {
            return true
        }
        return false
    }
    
}
