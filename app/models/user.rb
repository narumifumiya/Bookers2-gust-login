class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :books, dependent: :destroy
  has_one_attached :profile_image
  has_many :favorites, dependent: :destroy
  has_many :book_comments, dependent: :destroy

  # フォローするユーザーから見た中間テーブル
  has_many :relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy

  # 中間テーブルrelationshipsを通って、フォローされる側(followed)を集める処理をfollowingsと命名
  # フォローしているユーザーの情報がわかるようになる
  # フォロー一覧使用
  has_many :followings, through: :relationships, source: :followed

  # フォローされているユーザーから見た中間テーブル
  has_many :reverse_of_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy

  # 中間テーブルreverse_of_relationshipsを通って、フォローする側(follower)を集める処理をfollowersと命名
  # 　フォローされているユーザーの情報がわかるようになる
  # フォロワー一覧で使用
  has_many :followers, through: :reverse_of_relationships, source: :follower

  validates :name, uniqueness: true, length: { minimum: 2, maximum: 20 }
  validates :introduction, length: { maximum: 50 }

  def get_profile_image(width, height)
    unless profile_image.attached?
      file_path = Rails.root.join("app/assets/images/no_image.jpg")
      profile_image.attach(io: File.open(file_path), filename: "default-image.jpg", content_type: "image/jpeg")
    end
    profile_image.variant(resize_to_limit: [width, height]).processed
  end

  # フォローした時の処理（引数にはcurrent_userのidを入れる）コントローラーで使用する
  def follow(user_id)
    relationships.create(followed_id: user_id)
  end
  # フォローを外す時の処理（引数にはcurrent_userのidを入れる）コントローラーで使用する
  def unfollow(user_id)
    relationships.find_by(followed_id: user_id).destroy
  end
  # フォローしているか判定
  def following?(user)
    followings.include?(user)
  end

  # user検索時に使用 searchの検索方法によって条件分岐
  # searchesコントローラーにて使用
  def self.looks(search, word)
    if search == "perfect_match"
      User.where("name Like?", "#{word}")
    elsif search == "forward_match"
      User.where("name Like?", "#{word}%")
    elsif search == "backward_match"
      User.where("name Like?", "%#{word}")
    elsif search == "partial_match"
      User.where("name Like?", "%#{word}%")
    else
      User.all
    end
  end

  def self.guest
    find_or_create_by!(name: "guestuser", email: "guest@example.com") do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "guestuser"
    end
  end
end
