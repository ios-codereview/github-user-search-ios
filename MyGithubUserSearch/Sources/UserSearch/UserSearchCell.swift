//
//  UserSearchCell.swift
//  MyGithubUserSearch
//
//  Created by Jinwoo Kim on 06/05/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit
import Kingfisher

class UserSearchCell: UICollectionViewCell {
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var userItem: UserItem? {
        didSet {
            fillupCell(with: userItem)
        }
    }
    
    var didTapCellItem: ((Bool, UICollectionViewCell) -> ())?
    
    // MARK:- Cell screen properties
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        iv.addGestureRecognizer(tapGesture)
        return iv
    }()
    
    @objc private func handleTap() {
        print("Hello tap!!")
    }
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        label.addGestureRecognizer(tapGesture)
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    typealias OrganizationDataSource = RxCollectionViewSectionedReloadDataSource<Organization>
    
    private let dataSource = OrganizationDataSource(configureCell: { (dataSource, collectionView, indexPath, item) -> UICollectionViewCell in

        let cell = collectionView.dequeue(Reusable.organizationCell, for: indexPath)
        if let url = URL(string: item.avatarUrl) {
            cell.organizationImageView.kf.setImage(with: url)
        }
//        print("dataSource avatar: \(item.avatarUrl)")
        return cell
    })
    
    private let containerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        return cv
    }()
    
    // MARK:- Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCellSubviews()
        
        containerCollectionView.register(Reusable.organizationCell)
        setupContainerCollectionView()
        
//        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerCollectionView.isHidden = false
    }
    
    // MARK:- Setup layout methods
    private func setupCellSubviews() {
        let stackView =  UIStackView(arrangedSubviews: [usernameLabel, scoreLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = Metric.contentSpacing
        
        [profileImageView, stackView].forEach {
            addSubview($0)
        }
        
        profileImageView.anchor(top: topAnchor,
                                leading: leadingAnchor,
                                bottom: nil,
                                trailing: nil,
                                size: CGSize(width: Metric.profileImageSize, height: Metric.profileImageSize))
        profileImageView.layer.cornerRadius = Metric.profileImageSize / 2
        
        stackView.anchor(top: topAnchor,
                         leading: profileImageView.trailingAnchor,
                         bottom: profileImageView.bottomAnchor,
                         trailing: trailingAnchor,
                         padding: UIEdgeInsets(top: 0, left: Metric.profileSpacing, bottom: 0, right: 0))
    }
    
    private func setupContainerCollectionView() {
        addSubview(containerCollectionView)
        
        containerCollectionView.anchor(top: profileImageView.bottomAnchor,
                                       leading: leadingAnchor,
                                       bottom: bottomAnchor,
                                       trailing: trailingAnchor,
                                       padding: UIEdgeInsets(top: Metric.orgVerticalSpacing, left: 0, bottom: 0, right: 0))
    }
    
    private func fillupCell(with userItem: UserItem?) {
        guard let userItem = userItem else { return }
        profileImageView.loadImageUsingCache(with: userItem.avatarUrl)
        usernameLabel.text = userItem.username
        scoreLabel.text = "score: \(userItem.score.description)"
    }
    
    #warning("Need to refactor")
    // == States ==
    var isTappedAgain: Bool = false
}

extension UserSearchCell: ReactorKit.View {
    
    func bind(reactor: UserSearchCellReactor) {
        
        containerCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // Action Binding
//        tapGesture.rx.event
//            .take(1)
//            .withLatestFrom(reactor.state)
//            .map { $0.isTapped }
//            .filter { $0 == false }
//            .map { _ in self.userItem?.organizationsUrl}
//            .map { Reactor.Action.updateOrganizationUrl($0) }
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        
        // State Binding
        reactor.state
            .map { $0.avatarUrls }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .filter { $0.isEmpty == false }
            .map { [Organization(organizationItems: $0)] }
            .bind(to: containerCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isTapped }
            .subscribe(onNext: { [weak self] isTapped in
                guard let self = self else { return }
                self.didTapCellItem?(isTapped, self)
            })
            .disposed(by: disposeBag)
    }
}

extension UserSearchCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: containerCollectionView.frame.height, height: Metric.orgImageSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Metric.orgItemSpacing
    }
}

