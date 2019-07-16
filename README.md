# CollectionViewAdapter
CollectionView adpter

## No UICollectionView Delegate, DataSource

<br>

![SampleTestApp](https://github.com/pkh0225/CollectionViewAdapter/blob/master/ScreenShot.png)
### ↑↑ please refer test sample project 👾👾


<br>

### sample data set
```
        var testData = AdapterData()
        for i in 0...10 {
            let sectionInfo = SectionInfo()
            testData.append(sectionInfo)
            sectionInfo.header = CellInfo(contentObj: "@@ header @@ \(i)", sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 150) }, cellType: TestCollectionReusableView.self) { btn in
                guard let name = btn?.tag_name, let value = btn?.tag_value else { return }
                print("header btn ---- \(name) : \(value)")
            }
            sectionInfo.footer = CellInfo(contentObj: " --- footer --- \(i)", cellType: TestFooterCollectionReusableView.self)
            for j in 0...5 {
                let cellInfo = CellInfo(contentObj: "cell \(j)",
                    sizeClosure: { return CGSize(width: UIScreen.main.bounds.size.width, height: 50) },
                    cellType: TestCollectionViewCell.self) { btn in
                        guard let name = btn?.tag_name, let value = btn?.tag_value else { return }
                        print("cell btn ---- \(name) : \(value)")
                }
                sectionInfo.cells.append( cellInfo )
            }
        }
        
        collectoinView.data = testData
        collectoinView.reloadData()
```
