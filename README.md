# CollectionViewAdapter
CollectionView adpter

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## No UICollectionView Delegate, DataSource
## NO Cell Register

<br>
<img alt="timetable" src="https://github.com/pkh0225/CollectionViewAdapter/blob/master/ScreenShot.png" width="333">

### ↑↑ please refer test sample project 👾👾


<br>

### sample data set
```
        DispatchQueue.global().async {
            
            var testData = UICollectionViewAdapterData()
            for i in 0...10 {
                let sectionInfo = UICollectionViewAdapterData.SectionInfo()
                testData.sectionList.append(sectionInfo)
                sectionInfo.header = UICollectionViewAdapterData.CellInfo(contentObj: "@@ header @@ \(i)",
                                             sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 150) },
                                                cellType: TestCollectionReusableView.self) { (name, object) in
                                                    guard let object = object else { return }
                                                    print("header btn ---- \(name) : \(object)")
                                                }
                sectionInfo.footer = UICollectionViewAdapterData.CellInfo(contentObj: " --- footer --- \(i)", cellType: TestFooterCollectionReusableView.self)
                for j in 0...5 {
                    let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: "cell \(j)",
                                           sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 50) },
                                              cellType: TestCollectionViewCell.self) { (name, object) in
                                                    guard let object = object else { return }
                                                    print("cell btn ---- \(name) : \(object)")
                                             }
                    sectionInfo.cells.append( cellInfo )
                }
            }
            
            DispatchQueue.main.async {
                self.collectoinView.adapterData = testData
                self.collectoinView.reloadData()
            }
        }
```
