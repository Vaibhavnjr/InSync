import Foundation

#if ENABLE_FIREBASE && canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if ENABLE_FIREBASE && canImport(FirebaseCore)
import FirebaseCore
#endif

#if ENABLE_FIREBASE && canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#if ENABLE_FIREBASE && canImport(FirebaseStorage)
import FirebaseStorage
#endif

final class FirebaseService {
    static let shared = FirebaseService()

    private init() {}

    var currentUserId: String? {
        #if ENABLE_FIREBASE && canImport(FirebaseAuth)
        guard isFirebaseConfigured else {
            return LocalBackendService.shared.currentUserId
        }

        return Auth.auth().currentUser?.uid
        #else
        return LocalBackendService.shared.currentUserId
        #endif
    }

    var isFirebaseConfigured: Bool {
        #if ENABLE_FIREBASE && canImport(FirebaseCore)
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    func configureIfNeeded() {
        #if ENABLE_FIREBASE && canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("InSync: Firebase is not configured. Add GoogleService-Info.plist before testing backend flows.")
            return
        }

        FirebaseApp.configure()
        #endif
    }

    func createPair() async throws -> Pair {
        guard isFirebaseConfigured else {
            return try await LocalBackendService.shared.createPair()
        }

        #if ENABLE_FIREBASE && canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let userId = try await ensureAuthenticated()
        let database = try firestore()

        for _ in 0..<16 {
            let code = PairCodeFormatter.generate()
            let document = database.collection("pairs").document(code)
            let existing = try await getDocument(document)

            if existing.exists {
                continue
            }

            let now = Date().timeIntervalSince1970
            try await setData(
                [
                    "pairCode": code,
                    "createdAt": now,
                    "createdBy": userId,
                    "userA": userId,
                    "userB": "",
                    "status": PairStatus.waiting.rawValue
                ],
                for: document
            )

            return Pair(
                pairCode: code,
                createdBy: userId,
                userA: userId,
                userB: nil,
                status: .waiting,
                latestByUserA: nil,
                latestByUserB: nil
            )
        }

        throw InSyncError.invalidPair
        #else
        throw InSyncError.firebaseNotConfigured
        #endif
    }

    func joinPair(code: String) async throws -> Pair {
        guard isFirebaseConfigured else {
            return try await LocalBackendService.shared.joinPair(code: code)
        }

        #if ENABLE_FIREBASE && canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let normalizedCode = PairCodeFormatter.normalize(code)
        let userId = try await ensureAuthenticated()
        let document = try firestore().collection("pairs").document(normalizedCode)
        let snapshot = try await getDocument(document)

        guard snapshot.exists else {
            throw InSyncError.codeNotFound
        }

        let pair = try parsePair(snapshot)

        if let userB = pair.userB, !userB.isEmpty, userB != userId {
            throw InSyncError.pairAlreadyUsed
        }

        if pair.userA == userId {
            return pair
        }

        try await updateData(
            [
                "userB": userId,
                "status": PairStatus.connected.rawValue
            ],
            for: document
        )

        return try await fetchPair(pairCode: normalizedCode)
        #else
        throw InSyncError.firebaseNotConfigured
        #endif
    }

    func fetchPair(pairCode: String) async throws -> Pair {
        guard isFirebaseConfigured else {
            return try await LocalBackendService.shared.fetchPair(pairCode: pairCode)
        }

        #if ENABLE_FIREBASE && canImport(FirebaseFirestore)
        let snapshot = try await getDocument(try firestore().collection("pairs").document(pairCode))

        guard snapshot.exists else {
            throw InSyncError.codeNotFound
        }

        return try parsePair(snapshot)
        #else
        throw InSyncError.firebaseNotConfigured
        #endif
    }

    func sendDrawing(pngData: Data, pairCode: String, role: AppRole) async throws {
        guard isFirebaseConfigured else {
            return try await LocalBackendService.shared.sendDrawing(
                pngData: pngData,
                pairCode: pairCode,
                role: role
            )
        }

        #if ENABLE_FIREBASE && canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
        let userId = try await ensureAuthenticated()
        let imagePath = "drawings/\(pairCode)/\(userId)/latest.png"

        try await uploadPNG(pngData, path: imagePath)

        let now = Date().timeIntervalSince1970
        let document = try firestore().collection("pairs").document(pairCode)

        try await updateData(
            [
                role.latestFieldName: [
                    "imagePath": imagePath,
                    "updatedAt": now
                ]
            ],
            for: document
        )
        #else
        throw InSyncError.firebaseNotConfigured
        #endif
    }

    func refreshPartnerDrawing(pairCode: String, role: AppRole) async throws -> Date {
        guard isFirebaseConfigured else {
            return try await LocalBackendService.shared.refreshPartnerDrawing(
                pairCode: pairCode,
                role: role
            )
        }

        #if ENABLE_FIREBASE && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
        let pair = try await fetchPair(pairCode: pairCode)

        guard let metadata = pair.latestPartnerDrawing(for: role),
              !metadata.isEmpty else {
            throw InSyncError.noPartnerDrawing
        }

        let data = try await downloadData(path: metadata.imagePath)
        try WidgetStorageService.shared.savePartnerDrawing(
            data: data,
            updatedAt: metadata.updatedAt,
            partnerLabel: "your person"
        )

        return metadata.updatedAt
        #else
        throw InSyncError.firebaseNotConfigured
        #endif
    }
}

#if ENABLE_FIREBASE && canImport(FirebaseAuth) && canImport(FirebaseCore)
private extension FirebaseService {
    func ensureAuthenticated() async throws -> String {
        guard FirebaseApp.app() != nil else {
            throw InSyncError.firebaseNotConfigured
        }

        if let currentUser = Auth.auth().currentUser {
            return currentUser.uid
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            Auth.auth().signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let userId = result?.user.uid else {
                    continuation.resume(throwing: InSyncError.notAuthenticated)
                    return
                }

                continuation.resume(returning: userId)
            }
        }
    }
}
#endif

#if ENABLE_FIREBASE && canImport(FirebaseFirestore) && canImport(FirebaseCore)
private extension FirebaseService {
    func firestore() throws -> Firestore {
        guard FirebaseApp.app() != nil else {
            throw InSyncError.firebaseNotConfigured
        }

        return Firestore.firestore()
    }

    func getDocument(_ document: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            document.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: InSyncError.invalidPair)
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }

    func setData(_ data: [String: Any], for document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func updateData(_ data: [AnyHashable: Any], for document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.updateData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func parsePair(_ snapshot: DocumentSnapshot) throws -> Pair {
        guard let data = snapshot.data() else {
            throw InSyncError.invalidPair
        }

        let pairCode = data["pairCode"] as? String ?? snapshot.documentID
        let createdBy = data["createdBy"] as? String ?? ""
        let userA = data["userA"] as? String ?? ""
        let rawUserB = data["userB"] as? String
        let userB = rawUserB?.isEmpty == true ? nil : rawUserB
        let statusRawValue = data["status"] as? String ?? PairStatus.waiting.rawValue
        let status = PairStatus(rawValue: statusRawValue) ?? .waiting

        return Pair(
            pairCode: pairCode,
            createdBy: createdBy,
            userA: userA,
            userB: userB,
            status: status,
            latestByUserA: parseDrawingMetadata(data["latestByUserA"]),
            latestByUserB: parseDrawingMetadata(data["latestByUserB"])
        )
    }

    func parseDrawingMetadata(_ rawValue: Any?) -> DrawingMetadata? {
        guard let dictionary = rawValue as? [String: Any],
              let imagePath = dictionary["imagePath"] as? String,
              !imagePath.isEmpty else {
            return nil
        }

        let updatedAt = parseDate(dictionary["updatedAt"]) ?? Date()

        return DrawingMetadata(imagePath: imagePath, updatedAt: updatedAt)
    }

    func parseDate(_ rawValue: Any?) -> Date? {
        if let timestamp = rawValue as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = rawValue as? Date {
            return date
        }

        if let seconds = rawValue as? Double {
            return Date(timeIntervalSince1970: seconds)
        }

        if let seconds = rawValue as? Int {
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }

        return nil
    }
}
#endif

#if ENABLE_FIREBASE && canImport(FirebaseStorage) && canImport(FirebaseCore)
private extension FirebaseService {
    func uploadPNG(_ data: Data, path: String) async throws {
        guard FirebaseApp.app() != nil else {
            throw InSyncError.firebaseNotConfigured
        }

        let reference = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"

        let _: StorageMetadata? = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata?, Error>) in
            reference.putData(data, metadata: metadata) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: metadata)
                }
            }
        }
    }

    func downloadData(path: String) async throws -> Data {
        guard FirebaseApp.app() != nil else {
            throw InSyncError.firebaseNotConfigured
        }

        let reference = Storage.storage().reference().child(path)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            reference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: InSyncError.noPartnerDrawing)
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }
}
#endif
