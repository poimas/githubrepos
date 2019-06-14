//
//  ContributorsViewController.swift
//  githubrepos
//
//  Created by user on 2019. 06. 13..
//  Copyright © 2019. poimas. All rights reserved.
//

import UIKit

class ContributorsViewController: UITableViewController {
    
    var detailItem: GithubRepoElement? {
        didSet {
            configureView()
        }
    }
    
    @IBOutlet weak var sizeCount: UILabel!
    @IBOutlet weak var forkCount: UILabel!
    @IBOutlet weak var starGazers: UITextView!
    
    var contributors = [Contributor]()
    
    // MARK: - Setup
    
    func configureView() {
        title = detailItem?.fullName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        loadInfo()
        loadStarGazers()
        loadContributors()
    }
    
    // MARK: - Services
    
    func loadInfo() {
        guard let detailItem = detailItem else { return }
        guard let url = URL(string: detailItem.url) else { return }
        let task = URLSession.shared.githubRepoTask(with: url) { [weak self] githubRepo, response, error in
            DispatchQueue.main.async {
                self?.sizeCount.text = githubRepo?.size.description ?? "n.a"
                self?.forkCount.text = githubRepo?.forks.description ?? "n.a"
            }
        }
        task.resume()
    }
    
    func loadStarGazers() {
        guard let detailItem = detailItem else { return }
        guard let url = URL(string: detailItem.stargazersURL) else { return }
        let task = URLSession.shared.stargazersTask(with: url) { [weak self] stargazers, response, error in
            if let stargazers = stargazers {
                DispatchQueue.main.async {
                    self?.starGazers.text = stargazers.map{ $0.login }.sorted().joined(separator: ", ")
                }
            }
        }
        task.resume()
    }
    
    func loadContributors() {
        guard let detailItem = detailItem else { return }
        guard let url = URL(string: detailItem.contributorsURL) else { return }
        let task = URLSession.shared.contributorsTask(with: url) { [weak self] contributors, response, error in
            guard let contributors = contributors else { return }
            self?.contributors = contributors.sorted { $0.login < $1.login }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        task.resume()
    }
    
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                completion( UIImage(data: data))
            }
        }
        task.resume()
    }
    
    // MARK:- Table view (contributors)
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Contributors"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contributors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Contributor", for: indexPath) as! ContributorCell
        let contributor = contributors[indexPath.row]
        cell.name.text = contributor.login
        loadImage(from: contributor.avatarURL) { cell.avatar.image = $0 }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "\(contributors[indexPath.row].contributions) contributions", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
}

