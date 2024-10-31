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
            
        let testData = CVAData()
        for i in 0...10 {
            let sectionInfo = CVASectionInfo()
            testData.sectionList.append(sectionInfo)
            sectionInfo.header = CVACellInfo(cellType: TestHeadCollectionReusableView.self)
                .setContentObj("@@ header @@ \(i)\n1247\nasdighj")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "기본 layout으로 변경", message: "\(object) : \(name)")
                    self.collectionView.collectionViewLayout = self.layout
                })

            sectionInfo.footer = CVACellInfo(cellType: TestFooterCollectionReusableView.self)
                .setContentObj(" --- footer --- \(i)\nasdlk;fj\n213p4987")
                .setActionClosure({ [weak self] (name, object) in
                    guard let self else { return }
                    guard let object = object else { return }

                    alert(vc: self, title: "AutoSize Layout으로 변경", message: "\(object) : \(name)")
                    if #available(iOS 14.0, *) {
                        self.collectionView.setAutoSizeListCellLayout()
                    }
                })
            //
            for j in 0...3 {
                let contentObj: String
                if #available(iOS 14.0, *) {
                    // cell auto size test
                    contentObj = "cell (\(i) : \(j))\n12351235\n1235512345"
                }
                else {
                    // cell fix size
                    contentObj = "cell (\(i) : \(j))"
                }

                let cellInfo = CVACellInfo(cellType: TestCollectionViewCell.self)
                    .setContentObj(contentObj)
                    .setActionClosure({ [weak self] (name, object) in
                        guard let self else { return }
                        guard let object = object else { return }
                        alert(vc: self, title: name, message: "\(object)")
                    })

                sectionInfo.cells.append(cellInfo)
            }
        }
            
        self.collectoinView.adapterData = testData
        self.collectoinView.reloadData()
        
```
